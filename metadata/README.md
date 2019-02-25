# Regenerate metadata from redcap

## Fetch from redcap as `json/CC*.json`

This gets the set of scans to fetch metadata for from the struct pipeline
output dir (all scans with output) and writes the JSON files to `json/`.

```
./fetch_metadata.sh json/ ~/vol/dhcp-derived-data/derived_02Jun2018/derivatives
```

## Sanity-check redcap output

This checks the JSON output against the struct pipeline output. Make sure
every session has some data, and that the data looks OK. 

```
./sanity.rb json ~/vol/dhcp-derived-data/derived_02Jun2018/derivatives
```

Expect to see some `"in JSON but no dir"` errors for subjects where one of the
two or more scans failed the struct pipeline, or where one or more scans took
place after 02 June, or where one or more scans were not neonates.

Expect to see `"bad scan_validation"` for scans which were not validated but
passed struct. For example, the fetal trial scans.

## Create new `.tsv` files

Walk the `json/` dir and generate a set of `.tsv` files in `tsv/`.

```
./gen-metadata.rb tsv/ json/
```

