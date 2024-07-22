#!/bin/bash

# Testing 10 years of backups 4 per day
for y in {2015..2024}; do
  for m in {01..12}; do
    for d in {01..31}; do
      for i in $(seq 1 4); do
        h=$((i * 6 - 2))
        hh=$(printf "%02d" $h)
        # Name tested for whitespaces and sorting by date instead of name
        touch "Backup - $(pwgen 12) - $y-$m-$d $hh-00-00".zip
        ./lg-backup.sh -l 4 -s Less -c .counter -m ./*.zip
      done
    done
  done
done
