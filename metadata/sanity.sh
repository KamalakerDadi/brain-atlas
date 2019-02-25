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
  log "usage: $dollar_zero [OPTIONS] /path/to/participants.tsv"
  log "sanity-check a participants.tsv file"
  log ""
  log "options:"
  log "  -d | --derivatives DIR  fetch sessions.tsv files from DIR"
  log "  -s | --stop-on-error    stop on first error"
  log "  -l | --log FILE         log output to FILE"
  log "  -e | --err FILE         log errors to FILE"
  log "  -q | --quiet            hide log output"
  log "  -h | --help             show this message"
}

if [ $# -lt 1 ]; then
  usage
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--derivatives)  
      shift
      derivatives_dir="$1"
      ;;

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
      if [ x"$participants_tsv" != x"" ]; then
        err "participants set twice"
      fi
      participants_tsv=$(realpath $1)
      ;;

  esac

  shift
done

if [ x"$derivatives_dir" = x"" ]; then
  data_dir=$(dirname "$participants_tsv")
  derivatives_dir="$data_dir/derivatives"
fi

if ! [ -f "$participants_tsv" ]; then
  err "$participants_tsv" "not found"
fi

# associative array of participant ids
declare -A subject_table

n_subjects_found=0
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

  if ! [[ $age =~ ^[0-9]+\.[0-9]+$ ]]; then
    err "$subject" "bad age $age"
  fi

  session_tsv="$derivatives_dir/sub-$subject/sub-${subject}_sessions.tsv"

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
    scan_date=${columns[1]}
    age_at_scan=${columns[2]}

    # header line?
    if [ x"$session" == x"session_id" ]; then

      # scan_date was removed from newer session tsvs as being too personal
      if [ x"$scan_date" == x"age_at_scan" ]; then
        in_new_format=1
      fi

      continue
    fi

    if [ $in_new_format == 1 ]; then
      age_at_scan=$scan_date
      scan_date=
    fi

    if [ x"$session" == x"0" ]; then
      err "$subject" "has a 0 session id in sessions.tsv"
    fi

    if ! [[ $session =~ ^[0-9]+$ ]]; then
      err "$subject" "bad session id $session"
    fi

    if ! [ -d "$derivatives_dir/sub-$subject/ses-$session" ]; then
      err "$subject-$session" "listed in sessions.tsv, but dir does not exist"
    fi

    if [ $in_new_format == 0 ]; then
      if ! [[ $scan_date =~ ^[0-9]+_[0-9]+_[0-9]+$ ]]; then
        log "$subject-$session" "bad scan date $scan_date"
      fi
    fi

    if ! [[ $age_at_scan =~ ^[0-9]+\.[0-9]+$ ]]; then
      log "$subject-$session" "bad age at scan $age_at_scan"
    fi

    ((n_dirs_listed += 1))
  done < "$derivatives_dir/sub-$subject/sub-${subject}_sessions.tsv"

  if [ $n_dirs_listed -ne ${#session_dirs[@]} ]; then
    err "$subject" "session.tsv lists $n_dirs_listed sessions, but ${#session_dirs[@]} session directories exist"
  fi

done < "$participants_tsv"

subject_dirs=($derivatives_dir/sub-*)
if [ $n_subjects_found -ne ${#subject_dirs[@]} ]; then
  err "$participants_tsv" "$n_subjects_found subjects listed, but ${#subject_dirs[@]} subject directories exist" 
fi

err_report
