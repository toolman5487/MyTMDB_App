#!/usr/bin/env python3
"""Remove deleted source files from Xcode project.pbxproj while keeping all SDKs and Lottie assets."""

import re
from pathlib import Path
from typing import List, Set, Tuple

PBXPROJ = Path(__file__).resolve().parent.parent / "MyTMDB_App.xcodeproj" / "project.pbxproj"

KEEP_FILES = {
    "LoginViewController.swift",
    "LoginViewModel.swift",
    "AccountViewModel.swift",
    "AccountService.swift",
    "TMDBAuthService.swift",
    "TMDBAuthModels.swift",
    "AccountModel.swift",
    "Constants.swift",
    "ThemeFont.swift",
    "loadingAir.json",
    "loadingAnimation_blue.json",
    "Animation_popcorn.json",
}

KEEP_GROUPS = {
    "Login_View",
    "Account_ViewModel",
    "Account_Model",
    "Home_Service",
    "Network",
    "Service",
    "Models",
    "ViewModel",
    "View",
    "Config",
    "Animations",
    "Products",
    "MyTMDB_App",
    "MyTMDB_AppTests",
    "MyTMDB_AppUITests",
}

OBJECT_START = re.compile(r"^\t+([A-F0-9]{24}) /\* (.+?) \*/ = \{")


def parse_objects(body: str) -> List[Tuple[str, str, str]]:
    lines = body.splitlines(keepends=True)
    objects: List[Tuple[str, str, str]] = []
    i = 0

    while i < len(lines):
        line = lines[i]
        match = OBJECT_START.match(line)
        if not match:
            i += 1
            continue

        obj_id, name = match.group(1), match.group(2)
        block_lines = [line]

        if line.rstrip().endswith("};"):
            i += 1
        else:
            i += 1
            while i < len(lines):
                block_lines.append(lines[i])
                if lines[i].rstrip() == "};":
                    i += 1
                    break
                i += 1

        objects.append((obj_id, name, "".join(block_lines)))

    return objects


def should_keep(name: str, block: str) -> bool:
    if "isa = PBXFileReference;" in block:
        return name in KEEP_FILES
    if "isa = PBXBuildFile;" in block:
        if " in Sources" in name:
            return name.replace(" in Sources", "") in KEEP_FILES
        if " in Resources" in name:
            return name.replace(" in Resources", "") in KEEP_FILES
        return True
    if "isa = PBXGroup;" in block:
        return name in KEEP_GROUPS
    return True


def clean_children(block: str, removed_ids: Set[str]) -> str:
    cleaned = []
    for line in block.splitlines(keepends=True):
        child = re.match(r"^\t\t([A-F0-9]{24}) /\*.+\*/,?\s*$", line)
        if child and child.group(1) in removed_ids:
            continue
        cleaned.append(line)
    return "".join(cleaned)


def main() -> None:
    text = PBXPROJ.read_text()
    marker = "objects = {\n"
    start = text.index(marker) + len(marker)
    suffix_marker = "\n\t};\n\trootObject"
    end = text.index(suffix_marker)

    prefix = text[:start]
    body = text[start:end]
    suffix = text[end:]

    all_objects = parse_objects(body)
    removed_ids = {
        obj_id
        for obj_id, name, block in all_objects
        if not should_keep(name, block)
    }

    sections = re.split(r"(/\* Begin [^*]+ section \*/\n|/\* End [^*]+ section \*/\n)", body)
    rebuilt: List[str] = []

    for part in sections:
        if part.startswith("/* Begin") or part.startswith("/* End"):
            rebuilt.append(part)
            continue

        for obj_id, name, block in parse_objects(part):
            if obj_id not in removed_ids:
                rebuilt.append(clean_children(block, removed_ids))

    PBXPROJ.write_text(prefix + "".join(rebuilt) + suffix)
    print(
        f"Parsed {len(all_objects)} objects, "
        f"removed {len(removed_ids)}, kept {len(all_objects) - len(removed_ids)}"
    )


if __name__ == "__main__":
    main()
