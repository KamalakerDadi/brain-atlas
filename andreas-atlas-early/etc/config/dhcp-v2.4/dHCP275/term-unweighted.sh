## See etc/config/default.sh for documentation and full list of parameters

# import settings from spatio-temporal atlas construction
set_pardir_from_file_path "$BASH_SOURCE"
source "$topdir/$pardir/constant-sigma.sh"

sublst="$pardir/term-subjects.lst"

# regression parameters resulting in uniform weights
means=(40)
sigma=1000
epsilon=0
kernel="$pardir/term-unweighted"

# output settings
subdir="term-unweighted"
dagdir="dag/dHCP275/$subdir"
logdir="log/dHCP275/$subdir"
log="$logdir/progress.log"

resdir="dhcp-n275-t36_44/constructed-atlases/$subdir"
dofdir="../$resdir/dofs"
evldir="../$resdir/eval"
outdir="../$resdir/atlas"
tmpdir="../$resdir/temp"
