# Original atlas work

On 28 Jan 2018 Andreas wrote:

The atlas constructed for my thesis (which hasn’t changed since) is located at

```
/vol/dhcp-derived-data/volumetric-atlases/groupwise/output/dhcp-n275-t36_44-adaptive-sigma_1.00-nmi/atlas
```

The configuration file with parameters for the MIRTK command “construct-atlas” is:

```
/vol/dhcp-derived-data/volumetric-atlases/groupwise/config/adaptive-sigma_1.00-nmi.json
```

Constructing the atlas should be as simple as running:

```
mirtk construct-atlas adaptive-sigma_1.00-nmi.json
```

At the moment, you need to use the “develop” branch of my personal
GitHub fork of MIRTK:

https://github.com/schuhschuh/MIRTK/tree/develop

The goal for after I’ve done and submitted my thesis corrections is to
merge this into the official master branch.

# To rerun

Link Andreas's input data here, and link a spare directory on dhcp-server to
output:

```
./mklinks.sh
```

Run:

```
mirtk construct-atlas john-adaptive-sigma_1.00-nmi.json
```


