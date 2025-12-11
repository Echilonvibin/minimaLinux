#! /usr/bin/env python3
import subprocess
import json
import argparse
import time
from collections import defaultdict
from pathlib import Path

def load_bind_comments():
    """Scan Hyprland config files to map keybinds to inline #comments.

    Returns a dict keyed by a simple signature "MODS + KEY" -> comment.
    Example key: "SUPER + F5"
    """
    comment_map = {}
    # For key-only disambiguation, track multiple entries per key with their mod tokens
    comment_map_keyonly = {}
    hypr_dir = Path.home() / ".config" / "hypr"
    candidates = []
    if hypr_dir.exists():
        # Common file names
        for name in ["hyprland.conf", "binds.conf", "keybinds.conf", "keybindings.conf"]:
            p = hypr_dir / name
            if p.exists():
                candidates.append(p)
        # Include conf.d directory
        confd = hypr_dir / "conf.d"
        if confd.exists() and confd.is_dir():
            for p in sorted(confd.glob("*.conf")):
                candidates.append(p)

    def normalize_mods(mods_str):
        # Split by space or plus; keep order as Hyprctl computes mod_display sorted by mask
        parts = [s.strip().upper() for s in mods_str.replace("+", " ").split() if s.strip()]
        return " ".join(parts)

    def mods_tokens(mods_str):
        return [s.strip().upper() for s in mods_str.replace("+", " ").split() if s.strip()]

    for file_path in candidates:
        try:
            with file_path.open("r", encoding="utf-8") as f:
                for line in f:
                    # Support both 'bind =' and 'bind ='
                    if not line.strip().startswith("bind"):
                        continue
                    # Extract inline comment (after '#')
                    if "#" not in line:
                        continue
                    code, comment = line.split("#", 1)
                    comment = comment.strip()
                    # Basic parse: bind = mods, key, dispatcher, arg...
                    try:
                        _, rhs = code.split("=", 1)
                        parts = [p.strip() for p in rhs.split(",")]
                        if len(parts) < 3:
                            continue
                        mods = parts[0]
                        key = parts[1]
                        # Tail (dispatcher + args) to help disambiguate descriptions
                        tail = ",".join(parts[2:]).strip()
                        signature_full = f"{normalize_mods(mods)} + {key}"
                        # Store exact (mods + key) mapping
                        prev = comment_map.get(signature_full)
                        if not prev or len(comment) > len(prev):
                            comment_map[signature_full] = comment
                        # Store key-only entries with their mods tokens for later disambiguation
                        lst = comment_map_keyonly.setdefault(key, [])
                        lst.append((mods_tokens(mods), comment, tail))
                    except Exception:
                        continue
        except Exception:
            continue
    return comment_map, comment_map_keyonly

def get_hyprctl_binds():
    """Fetch binds from hyprctl in JSON format."""
    for _ in range(5):  # retry up to 5 times
        try:
            result = subprocess.run(
                ["hyprctl", "binds", "-j"],
                capture_output=True,
                text=True,
                check=True
            )
            return json.loads(result.stdout)
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            time.sleep(1)
    print("Failed to fetch binds after retries")
    return []

def parse_description(description):
    if description.startswith("[") and "] " in description:
        headers, main_description = description.split("] ", 1)
        headers = headers.strip("[").split("|")
    else:
        headers = ["Misc", "", "", ""]
        main_description = description

    return {
        "header1": headers[0] if headers else "",
        "header2": headers[1] if len(headers) > 1 else "",
        "header3": headers[2] if len(headers) > 2 else "",
        "header4": headers[3] if len(headers) > 3 else "",
        "description": main_description,
    }

def map_dispatcher(dispatcher):
    return {"exec": "execute"}.get(dispatcher, dispatcher)

def map_codeDisplay(keycode, key):
    if keycode == 0:
        return key
    code_map = {
        61: "slash", 87: "KP_1", 88: "KP_2", 89: "KP_3", 83: "KP_4", 84: "KP_5",
        85: "KP_6", 79: "KP_7", 80: "KP_8", 81: "KP_9", 90: "KP_0",
    }
    return code_map.get(keycode, key)

def map_modDisplay(modmask):
    modkey_map = {
        64: "SUPER", 32: "HYPER", 16: "META", 8: "ALT", 4: "CTRL", 2: "CAPSLOCK", 1: "SHIFT",
    }
    mod_display = []
    for key, name in sorted(modkey_map.items(), reverse=True):
        if modmask >= key:
            modmask -= key
            mod_display.append(name)
    return " ".join(mod_display) if mod_display else ""

def map_keyDisplay(key):
    key_map = {
        "edge:r:d": "Touch right edge downwards",
        "edge:r:l": "Touch right edge left",
        "edge:r:r": "Touch right edge right",
    }
    return key_map.get(key, key)

def expand_meta_data(binds_data):
    submap_keys = {}
    comment_map, comment_map_keyonly = load_bind_comments()
    for bind in binds_data:
        if bind.get("has_description", False):
            parsed_description = parse_description(bind["description"])
            bind.update(parsed_description)
        else:
            # Prefer inline comments in the bind arg as the user-facing description.
            arg = bind.get("arg", "") or ""
            inline_comment = None
            if isinstance(arg, str) and "#" in arg:
                # Take text after the first '#', strip whitespace
                inline_comment = arg.split("#", 1)[1].strip()
            if inline_comment:
                bind["description"] = inline_comment
            else:
                bind["description"] = f"{map_dispatcher(bind['dispatcher'])} {arg}"
            bind.update({"header1": "Misc", "header2": "", "header3": "", "header4": ""})
        bind["key"] = map_codeDisplay(bind["keycode"], bind["key"])
        bind["key_display"] = map_keyDisplay(bind["key"])
        bind["mod_display"] = map_modDisplay(bind["modmask"])
        if bind["dispatcher"] == "submap":
            submap_keys[bind["arg"]] = {
                "mod_display": bind["mod_display"],
                "key_display": bind["key_display"],
            }

    for bind in binds_data:
        submap = bind.get("submap", "")
        mod_display = bind["mod_display"] or ""
        key_display = bind["key_display"] or ""
        keys = " + ".join(filter(None, [mod_display, key_display]))
        if submap in submap_keys:
            sm = submap_keys[submap]
            bind["displayed_keys"] = f"{sm['mod_display']} + {sm['key_display']} + {keys}"
            bind["description"] = f"[{submap}] {bind['description']}"
        else:
            bind["displayed_keys"] = keys

        # If we still have a fallback description, try to replace it with config comment
        sig_full = bind.get("displayed_keys")
        sig_key_only = bind.get("key_display")
        if sig_full and sig_full in comment_map:
            bind["description"] = comment_map[sig_full]
        elif sig_key_only and sig_key_only in comment_map_keyonly:
            # Try to disambiguate by matching mod tokens
            desired_tokens = [t for t in (bind.get("mod_display") or "").split() if t]
            candidates = comment_map_keyonly.get(sig_key_only, [])
            # Exact token match first
            for tokens, cmt, _tail in candidates:
                if tokens == [t.upper() for t in desired_tokens]:
                    bind["description"] = cmt
                    break
            else:
                # Fallback: single candidate or longest comment
                if len(candidates) > 1:
                    # Try to match by arg similarity, prioritize '-m <mode>' exact match
                    import re
                    barg = (bind.get("arg") or "").strip()
                    mode_b = None
                    m = re.search(r"-m\s+(\w+)", barg)
                    if m:
                        mode_b = m.group(1).lower()
                    # Score candidates
                    best = None
                    best_score = -1
                    for _tokens, cmt, tail in candidates:
                        score = 0
                        if tail and barg:
                            if mode_b:
                                mt = re.search(r"-m\s+(\w+)", tail or "")
                                if mt and mt.group(1).lower() == mode_b:
                                    score += 10
                            # general overlap
                            overlaps = sum(1 for seg in (tail or "").split() if seg and seg in barg)
                            score += min(overlaps, 5)
                        if score > best_score:
                            best_score = score
                            best = cmt
                    if best is not None:
                        bind["description"] = best
                    else:
                        # Longest description as last resort
                        bind["description"] = max(candidates, key=lambda x: len(x[1]))[1]
                elif len(candidates) == 1:
                    bind["description"] = candidates[0][1]

def generate_rofi(binds):
    """Generate tab-separated rofi output: KEY ⟶ Description."""
    rofi_lines = []
    for bind in binds:
        if bind.get("catch_all", False):
            continue
        keys = bind.get("displayed_keys", "")
        description = bind.get("description", "")
        rofi_lines.append(f"{keys}\t{description}")
    return "\n".join(rofi_lines) if rofi_lines else "No keybinds found"

def generate_md(binds):
    return "\n".join(f"- **{b['displayed_keys']}**: {b['description']}" for b in binds)

def generate_dmenu(binds):
    return "\n".join(f"{b['displayed_keys']}\t{b['description']}" for b in binds)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Hyprland keybinds hint script")
    parser.add_argument("--show-unbind", action="store_true", help="Show duplicated keybinds")
    parser.add_argument("--format", choices=["json", "md", "dmenu", "rofi"], default="json", help="Output format")
    parser.add_argument("--prefer-comments", action="store_true", help="Prefer inline #comments from config over generated descriptions")
    args = parser.parse_args()

    binds_data = get_hyprctl_binds()
    if binds_data:
        # Determine preference from flag or env (default: prefer comments)
        import os
        prefer_env = os.environ.get("KEYHINTS_PREFER_COMMENTS")
        prefer_default = True if prefer_env is None else prefer_env not in ("0", "false", "False")
        prefer = args.prefer_comments or prefer_default

        if prefer:
            expand_meta_data(binds_data)
        else:
            # Call expand to build displays but skip comment replacement by stubbing loader
            _orig = load_bind_comments
            try:
                def _stub():
                    return {}, {}
                globals()['load_bind_comments'] = _stub
                expand_meta_data(binds_data)
            finally:
                globals()['load_bind_comments'] = _orig
        if args.show_unbind:
            bind_map = defaultdict(list)
            for bind in binds_data:
                key = (bind["mod_display"], bind["key_display"])
                bind_map[key].append(bind)
            for (mod_display, key_display), binds in bind_map.items():
                if len(binds) > 1:
                    print(f"unbind = {mod_display} , {key_display}")
        elif args.format == "json":
            print(json.dumps(binds_data, indent=4))
        elif args.format == "md":
            print(generate_md(binds_data))
        elif args.format == "dmenu":
            print(generate_dmenu(binds_data))
        elif args.format == "rofi":
            print(generate_rofi(binds_data))

