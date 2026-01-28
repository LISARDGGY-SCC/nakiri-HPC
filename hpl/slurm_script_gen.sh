NUM_GPUS=4
NUM_NODES=1
AUTO_SUBMIT=false
WORKSPACE=$(pwd)
SIF_PATH=$WORKSPACE/hpc-benchmarks:21.4.sif
SLURM_PART=test
HPL_NB=384
VRAM=32
FORCE=false

usage() {
        echo "Usage: %0 [options]"
        echo "Options:"
        echo "-g, --gpus <number>       setting gpu number, default $NUM_GPUS"
        echo "-n, --nodes <number>      setting node number, default $NUM_NODES"
        echo "-p, --partition <name>    setting slurm partition, default $SLURM_PART"
        echo "-s, --submit              auto submit, default $AUTO_SUBMIT"
        echo "-nb, --hpl-nb <number>    NB of hpl's .dat, default $HPL_NB"
        echo "-r, --gpu-vram <number>   <number>G VRAM per GPU, default $VRAM"
        echo "-h, --help                show this help"
        echo "-w, --workspace <path>    setting workspace, default \$(pwd) ($WORKSPACE)"
        echo "-f, --force               force generate new .dat file"
        exit 1
}

while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
                -g|--gpus)
                        NUM_GPUS="$2"
                        shift
                        shift
                        ;;
                -s|--submit)
                        AUTO_SUBMIT=true
                        shift
                        ;;
                -n|--nodes)
                        NUM_NODES="$2"
                        shift
                        shift
                        ;;
                -p|--partition)
                        SLURM_PART="$2"
                        shift
                        shift
                        ;;
                -nb|--hpl-nb)
                        HPL_NB="$2"
                        shift
                        shift
                        ;;
                -r|--gpu-vram)
                        VRAM="$2"
                        shift
                        shift
                        ;;
                -f|--force)
                        FORCE=true
                        shift
                        ;;
                -w|--workspace)
                        WORKSPACE="$2"
                        shift
                        shift
                        ;;
                -h|--help)
                        usage
                        ;;
                *)
                        echo "Unknow option: $1"
                        usage
                        ;;
        esac
done

CPU_PER_GPU=4
NUM_CPUS=$((NUM_GPUS * CPU_PER_GPU))
JOB_NAME="${NUM_NODES}node_${NUM_GPUS}gpu"
GPU_AFFINITY_STRING=$(seq -s : 0 $((NUM_GPUS-1)))

if [ ! -d "script" ]; then
	mkdir -p script
fi
SLURM_SCRIPT="script/run_${JOB_NAME}.sh"

cat <<EOF > ${SLURM_SCRIPT}
#!/bin/bash

#SBATCH --job-name=${JOB_NAME}
#SBATCH --nodes=${NUM_NODES}
#SBATCH --ntasks-per-node=${NUM_GPUS}
#SBATCH --ntasks-per-socket=4
#SBATCH --hint=nomultithread
#SBATCH --cpus-per-task=${CPU_PER_GPU}
#SBATCH --gres=gpu:${NUM_GPUS}
#SBATCH --gres-flags=enforce-binding
#SBATCH --time=00:10:00
#SBATCH --account=ACD114124
#SBATCH --partition=$SLURM_PART
#SBATCH --output=result/${JOB_NAME}.out

WRAPPER_SCRIPT="./wrapper_tmp"
cat << 'EOF_WRAPPER' > \$WRAPPER_SCRIPT
#!/bin/bash
echo "Debug: Allocated CPUs: \$(grep Cpus_allowed_list /proc/self/status | awk '{print \$2}')"

AVAIL_CPUID=\$(grep Cpus_allowed_list /proc/self/status | awk '{print \$2}')
CPU_LIST=\$(python3 -c "
input_str = '\$AVAIL_CPUID'
nums = []
for part in input_str.split(','):
    if '-' in part:
        s, e = map(int, part.split('-'))
        nums.extend(range(s, e + 1))
    else:
        nums.append(int(part))

groups = []
for i in range(0, len(nums), $CPU_PER_GPU):
    chunk = nums[i:i + $CPU_PER_GPU]
    groups.append(','.join(map(str, chunk)))

print(':'.join(groups))
")

SIF=$SIF_PATH

HPL="/workspace/hpl.sh"
DAT="--dat $WORKSPACE/datas/${VRAM}G_${NUM_NODES}node_${NUM_GPUS}GPU.dat"
CPU="--cpu-affinity \$CPU_LIST"
CPUpRANK="--cpu-cores-per-rank ${CPU_PER_GPU}"
GPU="--gpu-affinity ${GPU_AFFINITY_STRING}"

echo \$CPU \$CPUpRANK \$GPU
pwd

singularity run --nv \
        \$SIF \
        \$HPL \
        \$DAT \
        \$CPU \
        \$CPUpRANK \
        \$GPU
EOF_WRAPPER

chmod +x \$WRAPPER_SCRIPT

srun --cpu-bind=none --mpi=pmi2 \$WRAPPER_SCRIPT
rm \$WRAPPER_SCRIPT
EOF
echo "Generate ${SLURM_SCRIPT}"

if [ ! -d "datas" ]; then
	mkdir -p datas
fi
DOTDAT="datas/${VRAM}G_${NUM_NODES}node_${NUM_GPUS}GPU.dat"
if [ $FORCE ]; then
    rm $DOTDAT
fi

if [ ! -f $DOTDAT ]; then
    HPL_N=$(python3 -c "
tmpn = ($VRAM * 1024**3 * 0.9 * $NUM_NODES * $NUM_GPUS / 8) ** 0.5
nb = $HPL_NB
n = (tmpn // nb) * nb
print(int(n))
")
    cat << EOF > $DOTDAT
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
$HPL_N Ns
1            # of NBs
$HPL_NB          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
1            Ps
1            Qs
16.0         threshold
1            # of panel fact
0 1 2        PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
2 8          NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
0 1 2        RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
3 2          BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
1 0          DEPTHs (>=0)
1            SWAP (0=bin-exch,1=long,2=mix)
192          swapping threshold
1            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
0            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOF
echo "Generate ${DOTDAT}"
echo "You should modify the PQ in .dat file!!!"
fi

if [ "$AUTO_SUBMIT" = true ]; then
        sbatch ${SLURM_SCRIPT}
fi
