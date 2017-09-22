# Copyright (c) 2017, Cody Opel <codyopel@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Hardcodes prefixs of all dependencies.
#PATH#

#deluge-console -c /home35/jackal/.config/deluge/ "connect 5.79.67.48:21096 jackal DgVlV6HtNqW; info 30435a5872d07b226051516949bb04b1bfcfaf5a"

# XXX: tpslimit is purposely set fairly low to prevent sending to many
#      api requests at once since rclone does not throttle requests.

# Get necessary XDG directories or use defaults if undefined
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if [ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
  source "$XDG_CONFIG_HOME/user-dirs.dirs"
elif [ -f '/etc/xdg/user-dirs.defaults' ]; then
  source '/etc/xdg/user-dirs.defaults'
fi
XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Download}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_DOWNLOAD_DIR

CONFIG_DIR="${CONFIG_DIR:-$XDG_CONFIG_HOME/conveyor}"

if [ ! -f "$CONFIG_DIR/config" ]; then
  install -D -m600 -v "$PREFIX/share/conveyor/config.template" \
    "$CONFIG_DIR/config"
fi

source "$CONFIG_DIR/config"

if [ "$DOWNLOAD_COMPLETE_DIR" == "$DOWNLOAD_DATA_DIR" ]; then
  echo "ERROR: DOWNLOAD_COMPLETE_DIR and DOWNLOAD_DATA_DIR must be different directories" >&2
  exit 1
fi

declare -a -r Vars=(
  DOWNLOAD_COMPLETE_DIR
  DOWNLOAD_DATA_DIR
  RCLONE_REMOTE
  RCLONE_REMOTE_OFFLOAD_DIR
  RCLONE_REMOTE_SORTED_DIR
)
for Var in "${Vars[@]}"; do
  eval VarEval="\$$Var"
  if [ -z "$VarEval" ]; then
    echo "ERROR: $Var undefined" >&2
    exit 1
  fi
done

declare -a -r Bins=(
  awk
  grep
  guessit
  jq
  rclone
  sed
)
for Bin in "${Bins[@]}"; do
  if ! type $Bin >/dev/null; then
    echo "ERROR: required executable not found: $Bin" >&2
    exit 1
  fi
done


# FIXME: add to lib-bash
map() {
  if [ $# -le 1 ]; then
    return
  else
    local Command="$1"
    local Arg="$2"
    shift 2
    local -a Args=("$@")

    $Command "$Arg"

    map "$Command" "${Args[@]}"
  fi
}

archive_ext() {
  local Extension
  local -r File="$1"

  # FIXME: use grep perl regex

  # Find correct RAR file extension
  if [ "${File##*.}" == 'r00' ]; then
    Extension='r00'
  elif [ "${File##*.}" == 'rar' ]; then
    # FIXME: will break on filenames with periods
    if [ "${File#*.}" == 'part01.rar' ]; then
      Extension='part01.rar'
    elif [ "${File#*.}" == 'subs.rar' ]; then
      Extension='subs.rar'
    else
      Extension='rar'
    fi
  elif [ "${File##*.}" == 'zip' ]; then
    Extension='zip'
  else
    echo "ERROR: unknown archive extension: ${File}" >&2
    return 1
  fi

  echo "$Extension"
}

archive_utility() {
  local -r Archive="$1"
  local Type

  Type="$(archive_type "$Archive")"

  if [ "$Type" == 'rar' ]; then
    if type 'unrar' >/dev/null; then
      echo 'unrar'
    elif type '7za' >/dev/null; then
      echo '7z'
    else
      return 2
    fi
  else
    return 1
  fi
}

archive_type() {
  local Extension
  local -r File="$1"

  Extension="$(archive_ext "$File")"

  case "$Extension" in
    'r00'|'rar'|'part01.rar'|'subs.rar') echo 'rar' ;;
    'zip') echo 'zip' ;;
    *) return 1 ;;
  esac
}

archive_unpack() {
  local -r Archive="$1"
  local -r Destination="$2"
  local ArchiveUtility

  ArchiveUtility="$(archive_utility "$Archive")"

  echo "unpacking: $Archive -> $Destination" >&2

  case "$ArchiveUtility" in
    'unrar')
      unrar x -p- -o+ "$Archive" "$Destination"
      ;;
    '7z')
      7z e -r -ao "$Archive" -o "$Destination"
      ;;
    *)
      echo "unknown utility: $ArchiveUtility" >&2
      return 1
      ;;
  esac
}

archive_scan() {
  local Archive
  local -a Archives
  local -r Dir="$1"

  # XXX: fucking scene cunts nest rar archives, *.subs.rar contains
  #      *.idx and *.rar which has the sub file.
  find_archives() {
    local -r Dir2="$1"
    RCLONE_LS_EXTRA_ARGS='--include *.{rar,zip}' rc_ls "$Dir2"
  }

  set +o nounset
  while true; do
    Archives=()
    mapfile -t Archives < <(find_archives "$Dir")
    if [ -n "${Archives[*]}" ]; then
      for Archive in "${Archives[@]}"; do
        pushd "$Dir"
        archive_unpack "$Archive" "$(dirname "$Archive")"
        rm -fv "$Archive"
        popd
      done
    else
      break
    fi
  done
  set -o nounset
}

build_index () {
  local -a Array
  local i
  local -r Name="$1"
  declare -A -g ${Name}Index

  eval Array=("\"\${${Name}[@]}\"")

  set +o nounset
  for i in "${!Array[@]}"; do
    eval ${Name}Index["${Array["$i"]}"]="$i"
  done
  set -o nounset
}

guessit_wrapper() {
  local -r Input="$1"
  local TmpFile

  TmpFile="$(mktemp)"
  TMP_FILES_LIST+=("$TmpFile")

  guessit --json --advanced --enforce-list "$Input" > "$TmpFile"

  echo "$TmpFile"
}

# FIXME: currently we only take the first elem returned
guessit_container() {
  local -r File="$1"

  jq -r -c -M '.container[0]|select(.value != null)|.value' "$File"
}

guessit_season() {
  local -r File="$1"

  jq -r -c -M '.season[0]|select(.value != null)|.value' "$File"
}

guessit_title() {
  local -r File="$1"

  jq -r -c -M '.title[0]|select(.value != null)|.value' "$File"
}

guessit_type() {
  local -r File="$1"

  jq -r -c -M '.type[0].value' "$File"
}

guessit_year() {
  local -r File="$1"

  jq -r -c -M '.year[0]|select(.value != null)|.value' "$File"
}

guessit_date() {
  local -r File="$1"

  jq -r -c -M '.date[0]|select(.value != null)|.value' "$File"
}

guessit_date_raw() {
  local -r File="$1"

  jq -r -c -M '.date[0]|select(.raw != null)|.raw' "$File"
}

normalize_string() {
  local -r String="$1"

  echo "$String" |
      tr [A-Z] [a-z] |
      # Sanitize illegal characters from title
      sed -e 's/:\s/-/g' \
        -e 's/\./ /g' \
        -e "s/'//g" \
        -e 's/!//g' \
        -e 's/,//' \
        -e 's/?//' \
        -e 's/://' \
        -e 's/&/and/'
}

relative_to_complete_dir() {
  Function::RequiredArgs '1' "$#"
  local -r Path="$1"
  local RelativePath

  RelativePath="$(echo "$Path" | sed -e "s,$DOWNLOAD_COMPLETE_DIR/,,")"

  echo "$RelativePath"
}

sort_char() {
  local -r String="$1"

  echo "$String" |
    # Ignore indefinite articles
    sed -e 's/^[Aa]\s//g' \
      -e 's/^[Aa]n\s//g' \
      -e 's/^[Tt]he\s//g' |
    # Negate non-alphanumeric characters
    sed -e 's/[^[:alnum:]]//g' |
    cut -c 1
}

tolower() { echo ${@,,} ; }

clear_empty_dirs() {
  local -r Dir="$1"

  rclone rmdirs \
    -vv \
    --low-level-retries 20 \
    --tpslimit 4 \
    --tpslimit-burst 10 \
    "$Dir" || true
}

rc_ls() {
  local -r Dir="$1"

  rclone ls \
    -vv \
    --low-level-retries 20 \
    --fast-list \
    --tpslimit 4 \
    --tpslimit-burst 10 \
    ${RCLONE_LS_EXTRA_ARGS:-} \
    "$Dir" |
    # Print all but the first element (size).
    awk '{$1=""; print $0}' |
    # Remove leading/trailing whitespace
    sed -e 's/^\s\+//' -e 's/\s\+$//' 2>&- || true
}

rc_lsd() {
  local -r Dir="$1"

  rclone lsd \
    -vv \
    --low-level-retries 20 \
    --fast-list \
    --tpslimit 4 \
    --tpslimit-burst 10 \
    ${RCLONE_LS_EXTRA_ARGS:-} \
    "$Dir" |
    # Print all but the first element (size).
    awk '{$1="";$2="";$3="";$4=""; print $0}' |
    # Remove leading/trailing whitespace
    sed -e 's/^\s\+//' -e 's/\s\+$//' 2>&- || true
}

rc_mkdir() {
  local -r Dir="$1"

  rclone mkdir -vv --low-level-retries 20 "$Dir"
}

# XXX: rclone move does not yet support moving files accross filesystem
#      boundaries.  Maybe use copy, then delete source.
rc_move() {
  local -r SourceDir="$1"
  local -r TargetDir="$2"

  rclone move \
    "${RCLONE_EXTRA_OPTS[@]}" \
    "$SourceDir" "$TargetDir"
}
