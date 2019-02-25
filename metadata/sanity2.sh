#!/bin/bash

# set -x
# set -e

dollar_zero="$0"
participants_tsv=
stop_on_error=no
log_output=/dev/stdout
err_output=/dev/stderr
quiet=no

# associate array of error name -> "id1 id2 id3"
declare -A error_table

# id .. eg. CC00085XXAB
# name ... eg. "no sessions found"
err() {
  id=$1
  name=$2

  echo "$id $name" >> "$err_output"

  error_table[$name]="${error_table[$name]} $id"

  if [ x"stop_on_error" == x"yes" ]; then
    exit 1
  fi
}

err_report() {
  echo "# Error report - $(date)"
  echo ""
  for name in "${!error_table[@]}"; do 
    echo "## $name"
    echo ""
    for id in ${error_table[$name]}; do
      echo $id
    done
    echo ""
  done
}

log() {
  if [ x"$quiet" == x"no" ]; then
    echo "$*" >> "$log_output"
  fi
}

run() {
  log "$@"
  "$@" >> "$log_output" 2>> "$err_output"
  if ! [ $? -eq 0 ]; then
    err "failed, see $log_output and $err_output for details"
  fi
}

usage() {
  log "usage: $dollar_zero [OPTIONS] /path/to/tsv /path/to/derivatives"
  log "sanity-check a set of tsv files"
  log ""
  log "options:"
  log "  -s | --stop-on-error    stop on first error"
  log "  -l | --log FILE         log output to FILE"
  log "  -e | --err FILE         log errors to FILE"
  log "  -q | --quiet            hide log output"
  log "  -h | --help             show this message"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--stop-on-error)  
      stop_on_error=yes
      ;;

    -l|--log)  
      shift
      log_output="$1"
      ;;

    -e|--err)  
      shift
      err_output="$1"
      ;;

    -q|--quiet)  
      quiet=yes 
      ;;

    -h|--help)  
      usage
      exit 0 
      ;;

    -*) 
      err "unrecognized option $1" 
      ;;

    *) 
      break
      ;;

  esac

  shift
done

if [ $# -ne 2 ]; then
  usage
  exit 0
fi

tsv_dir="$1"
derivatives_dir="$2"
participants_tsv="$tsv_dir/participants.tsv"

if ! [ -f "$participants_tsv" ]; then
  err "$participants_tsv" "not found"
fi

# associative array of participant ids
declare -A subject_table

n_subjects_found=0
n_scans_found=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  columns=($line)
  subject=${columns[0]}
  gender=${columns[1]}
  age=${columns[2]}

  # header line?
  if [ x"$subject" == x"participant_id" ]; then
    continue
  fi

  if [[ x${subject_table[$subject]} != x"" ]]; then
    err "$subject" "duplicate subject"
    continue
  fi
  subject_table[$subject]=present

  if ! [ -d "$derivatives_dir/sub-$subject" ]; then
    err "$subject" "listed in participants.tsv, but dir does not exist"
    continue
  fi

  ((n_subjects_found += 1))

  if [ $gender != Male ] && [ $gender != Female ]; then
    err "$subject" "bad gender $gender"
  fi

  if ! [[ $age =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    err "$subject" "bad age $age"
  fi

  session_tsv="$tsv_dir/sub-${subject}_sessions.tsv"

  if ! [ -f "$session_tsv" ]; then
    err "$session_tsv" "missing session file"
    continue
  fi

  session_dirs=($derivatives_dir/sub-$subject/ses-*)

  n_dirs_listed=0
  in_new_format=0
  while IFS='' read -r line || [[ -n "$line" ]]; do
    columns=($line)
    session=${columns[0]}
    age_at_scan=${columns[1]}

    # header line?
    if [ x"$session" == x"session_id" ]; then
      continue
    fi

    ((n_dirs_listed += 1))

    if [ x"$session" == x"0" ]; then
      err "$subject" "has a 0 session id in sessions.tsv"
      continue
    fi

    if ! [[ $session =~ ^[0-9]+$ ]]; then
      err "$subject" "bad session id $session"
      continue
    fi

    ses_dir="$derivatives_dir/sub-$subject/ses-$session"
    if ! [ -d "$ses_dir" ]; then
      err "$subject-$session" "listed in sessions.tsv, but dir does not exist"
      continue
    fi

    T2_file="$ses_dir/anat/sub-${subject}_ses-${session}_T2w.nii.gz"
    if ! [ -f "$T2_file" ]; then
      err "$subject-$session" "listed in sessions.tsv, but T2 does not exist"
      continue
    fi

    if ! [[ $age_at_scan =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      err "$subject-$session" "bad age at scan $age_at_scan"
      continue
    fi

    ((n_scans_found += 1))
  done < "$session_tsv"

  if [ $n_dirs_listed -ne ${#session_dirs[@]} ]; then
    err "$subject" "session.tsv lists $n_dirs_listed sessions, but ${#session_dirs[@]} session directories exist"
  fi

done < "$participants_tsv"

subject_dirs=($derivatives_dir/sub-*)
if [ $n_subjects_found -ne ${#subject_dirs[@]} ]; then
  err "$participants_tsv" "$n_subjects_found subjects listed, but ${#subject_dirs[@]} subject directories exist" 
fi

echo "$n_scans_found good scans found"


err_report
