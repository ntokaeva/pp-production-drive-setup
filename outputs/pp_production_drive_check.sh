#!/usr/bin/env zsh
set -u
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin:${PATH:-}"

# Paper Planes production Drive checker.
# Read-only diagnostic: does not create, move, delete, or edit files.

PROJECT_QUERY="${1:-}"

TARGET_RG2_ID="18OdPDOhWblfsSOhyKw5z2kyGRM2nxGpu"
TARGET_IMPL_ID="1GFqllhIRkM_j9GR7Vxj1_Bh4uMCHYvLi"

print_section() {
  printf "\n== %s ==\n" "$1"
}

exists_line() {
  local path="$1"
  if [[ -e "$path" ]]; then
    printf "OK   %s\n" "$path"
  else
    printf "MISS %s\n" "$path"
  fi
}

add_target_candidate() {
  local label="$1"
  local path="$2"
  if [[ "$path" == *"ручная папка"* || "$path" == *"не использовать"* ]]; then
    return
  fi
  if (( ${TARGET_CANDIDATES[(Ie)$path]} == 0 )); then
    TARGET_CANDIDATES+=("$path")
    printf "%-4s %s\n" "$label" "$path"
  fi
}

add_project_match() {
  local path="$1"
  if (( ${PROJECT_MATCHES[(Ie)$path]} == 0 )); then
    PROJECT_MATCHES+=("$path")
    printf "FOUND %s\n" "$path"
  fi
}

print_section "Google Drive app"
if pgrep -f "Google Drive" >/dev/null 2>&1; then
  printf "OK   Google Drive process is running\n"
else
  printf "WARN Google Drive process is not visible\n"
fi

print_section "CloudStorage roots"
DRIVE_ROOTS=()
for root in "$HOME"/Library/CloudStorage/GoogleDrive-*; do
  [[ -d "$root" ]] || continue
  DRIVE_ROOTS+=("$root")
  printf "OK   %s\n" "$root"
done

if (( ${#DRIVE_ROOTS[@]} == 0 )); then
  printf "FAIL No GoogleDrive-* folders found in ~/Library/CloudStorage\n"
  printf "Install or sign in to Google Drive for desktop, then run this checker again.\n"
  exit 1
fi

print_section "Production roots"
PRODUCTION_ROOTS=()
for root in "${DRIVE_ROOTS[@]}"; do
  for candidate in \
    "$root/Shared drives/Paper Planes/4. Производство" \
    "$root/Shared drives/Paper Planes/04. Производство" \
    "$root/Общие диски/Paper Planes/4. Производство" \
    "$root/Общие диски/Paper Planes/04. Производство"; do
    if [[ -d "$candidate" ]]; then
      PRODUCTION_ROOTS+=("$candidate")
      printf "OK   %s\n" "$candidate"
    fi
  done
done

if (( ${#PRODUCTION_ROOTS[@]} == 0 )); then
  printf "FAIL Production folder was not found under Shared drives/Paper Planes.\n"
  printf "Open Google Drive for desktop and make sure Shared drives/Paper Planes is available.\n"
  exit 2
fi

print_section "Target folders"
TARGET_CANDIDATES=()
for prod in "${PRODUCTION_ROOTS[@]}"; do
  RG2_EXACT=(
    "$prod/RG2 Vault/70_Activities/70.1_Engagements/70.1.2_RG2"
  )
  for path in "${RG2_EXACT[@]}"; do
    if [[ -d "$path" ]]; then
      add_target_candidate "RG2" "$path"
    fi
  done

  # Fallback for machines where the folder was synced under a localized or older name.
  while IFS= read -r path; do
    [[ "$path" == *"archive"* || "$path" == *"Archive"* ]] && continue
    [[ "$path" == *"ручная папка"* || "$path" == *"не использовать"* ]] && continue
    [[ "$path" == *"Standards"* || "$path" == *"Templates"* ]] && continue
    add_target_candidate "RG2" "$path"
  done < <(/usr/bin/find "$prod" -maxdepth 8 -type d \( -iname "70.1.2*RG2*" -o -iname "70.1.2*РГ2*" \) 2>/dev/null | /usr/bin/sort)

  while IFS= read -r path; do
    [[ "$path" == *"archive"* || "$path" == *"Archive"* ]] && continue
    [[ "$path" == *"ручная папка"* || "$path" == *"не использовать"* ]] && continue
    if [[ "$path" != *"РГ1"* && "$path" != *"RG1"* && "$path" != *"70.1.1"* ]]; then
      continue
    fi
    add_target_candidate "IMPL" "$path"
  done < <(/usr/bin/find "$prod" -maxdepth 4 -type d \( -iname "*Реализа*" -o -iname "*Realiz*" -o -iname "*Implementation*" \) 2>/dev/null | /usr/bin/sort)
done

if (( ${#TARGET_CANDIDATES[@]} == 0 )); then
  printf "WARN No obvious RG2 / Implementation target folders found by name.\n"
  printf "Manual links to check in browser:\n"
  printf "     https://drive.google.com/drive/folders/%s\n" "$TARGET_RG2_ID"
  printf "     https://drive.google.com/drive/folders/%s\n" "$TARGET_IMPL_ID"
fi

print_section "Local availability"
for path in "${TARGET_CANDIDATES[@]}"; do
  exists_line "$path"
done

if [[ -z "$PROJECT_QUERY" ]]; then
  print_section "Project lookup"
  printf "No project name passed.\n"
  printf "Run example:\n"
  printf "  %s \"Гартенн\"\n" "$0"
  exit 0
fi

print_section "Project lookup: $PROJECT_QUERY"
PROJECT_MATCHES=()
for target in "${TARGET_CANDIDATES[@]}"; do
  while IFS= read -r path; do
    if [[ "$path" == "$target" ]]; then
      continue
    fi
    rel="${path#$target/}"
    project_root="${target}/${rel%%/*}"
    add_project_match "$project_root"
  done < <(/usr/bin/find "$target" -maxdepth 6 -type d -iname "*$PROJECT_QUERY*" 2>/dev/null | /usr/bin/sort)
done

print_section "Decision"
case "${#PROJECT_MATCHES[@]}" in
  0)
    printf "STOP Project was not found in production folders.\n"
    printf "Do not create a folder silently. Ask Natalia where the project should live.\n"
    ;;
  1)
    printf "OK   Save new project files here:\n"
    printf "     %s\n" "${PROJECT_MATCHES[1]}"
    ;;
  *)
    printf "STOP Project was found in more than one place.\n"
    printf "Ask Natalia which folder is canonical before saving files.\n"
    ;;
esac
