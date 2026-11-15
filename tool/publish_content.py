import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PUBLISHED = ROOT / "firebase" / "published"
SITE = ROOT / "firebase" / "content"
PROJECTS = {"dev": "gestura-dev-9ca1a", "prod": "gestura-prod"}
LANGUAGES = {"en", "ar", "ru", "es", "fr", "de"}
STEP_TYPES = {"learn", "chooseWord", "chooseVideo"}
QUIZ_OPTIONS = 4


def fail(message):
    sys.exit(f"Not published: {message}")


def check_text(value, where):
    if not isinstance(value, dict) or "en" not in value:
        fail(f"{where} needs an English text")
    if not set(value) <= LANGUAGES or not all(isinstance(v, str) and v for v in value.values()):
        fail(f"{where} has an unknown language or an empty text")


def validate(catalog, folder):
    if catalog.get("version") != 1:
        fail("catalog version must be 1")
    pack = catalog.get("pack") or {}
    if not isinstance(pack.get("code"), str) or not pack["code"]:
        fail("pack needs a code")
    check_text(pack.get("name"), "pack name")
    if pack.get("fingerspelling") not in {"oneHanded", "twoHanded"}:
        fail("pack fingerspelling must be oneHanded or twoHanded")
    if not isinstance(pack.get("placeholder"), bool):
        fail("pack placeholder must be true or false")
    categories = {c.get("id") for c in catalog.get("categories", [])}
    for category in catalog.get("categories", []):
        check_text(category.get("name"), f"category {category.get('id')}")
    signs = {}
    for sign in catalog.get("signs", []):
        sign_id = sign.get("id")
        if sign.get("category") not in categories:
            fail(f"sign {sign_id} has an unknown category")
        check_text(sign.get("meaning"), f"sign {sign_id}")
        if not isinstance(sign.get("durationMs"), int) or sign["durationMs"] <= 0:
            fail(f"sign {sign_id} needs a positive durationMs")
        source = sign.get("source") or {}
        if not source.get("name") or not source.get("license"):
            fail(f"sign {sign_id} needs a source name and license")
        for field in ("video", "thumbnail"):
            if not (folder / sign.get(field, "")).is_file():
                fail(f"sign {sign_id} {field} file is missing: {sign.get(field)}")
        signs[sign_id] = sign
    if not signs:
        fail("the catalog has no signs")
    for course in catalog.get("courses", []):
        check_text(course.get("title"), f"course {course.get('id')}")
        units = {unit.get("index") for unit in course.get("units", [])}
        for lesson in course.get("lessons", []):
            lesson_id = lesson.get("id")
            check_text(lesson.get("title"), f"lesson {lesson_id}")
            if lesson.get("unit") not in units:
                fail(f"lesson {lesson_id} has an unknown unit")
            for step in lesson.get("steps", []):
                if step.get("type") not in STEP_TYPES or step.get("sign") not in signs:
                    fail(f"lesson {lesson_id} has a broken step")
                if step["type"] != "learn":
                    options = step.get("options", [])
                    if len(options) != QUIZ_OPTIONS or step["sign"] not in options:
                        fail(f"lesson {lesson_id} quiz needs {QUIZ_OPTIONS} options with the answer")
                    if any(option not in signs for option in options):
                        fail(f"lesson {lesson_id} quiz has an unknown option")
    return pack


def hashed_copy(source, target_folder):
    digest = hashlib.sha256(source.read_bytes()).hexdigest()[:12]
    name = f"{source.stem}.{digest}{source.suffix}"
    target_folder.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target_folder / name)
    return f"media/{name}"


def write_index(output, packs):
    output.mkdir(parents=True, exist_ok=True)
    (output / "index.json").write_text(
        json.dumps({"version": 1, "packs": packs}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def read_index(output):
    index = output / "index.json"
    if not index.exists():
        return []
    return json.loads(index.read_text(encoding="utf-8"))["packs"]


def publish(catalog_path, target):
    folder = catalog_path.parent
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    pack = validate(catalog, folder)
    if target == "prod" and pack["placeholder"]:
        fail("placeholder content is never published to prod")
    code = pack["code"]
    output = PUBLISHED / target / "content"
    destination = output / code
    if destination.exists():
        shutil.rmtree(destination)
    for sign in catalog["signs"]:
        for field in ("video", "thumbnail"):
            sign[field] = hashed_copy(folder / sign[field], destination / "media")
    (destination / "catalog.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    packs = [p for p in read_index(output) if p["code"] != code]
    packs.append({"code": code, "catalog": f"{code}/catalog.json"})
    write_index(output, packs)
    print(f"Prepared {code}: {len(catalog['signs'])} signs in {destination}")


def deploy(target):
    output = PUBLISHED / target / "content"
    if not (output / "index.json").exists():
        write_index(output, [])
    if target == "prod":
        for entry in read_index(output):
            catalog = json.loads((output / entry["catalog"]).read_text(encoding="utf-8"))
            if catalog["pack"]["placeholder"]:
                fail("placeholder content is never published to prod")
    if SITE.exists():
        shutil.rmtree(SITE)
    shutil.copytree(output, SITE / "content")
    subprocess.run(
        ["firebase", "deploy", "--only", "hosting:content", "--project", PROJECTS[target]],
        cwd=ROOT,
        check=True,
    )


def main():
    parser = argparse.ArgumentParser(description="Validate and publish a content pack.")
    parser.add_argument("target", choices=sorted(PROJECTS))
    parser.add_argument("catalog", nargs="?", type=pathlib.Path)
    parser.add_argument("--deploy", action="store_true")
    args = parser.parse_args()
    if args.catalog:
        publish(args.catalog.resolve(), args.target)
    if args.deploy:
        deploy(args.target)


if __name__ == "__main__":
    main()
