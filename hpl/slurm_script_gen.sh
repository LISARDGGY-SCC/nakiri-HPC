#!/bin/bash

NUM_GPUS=4
NUM_NODES=1
AUTO_SUBMIT=false

usage() {
        echo "Usage: %0 [options]"
        echo "Options:"
        echo "-g, --gpus <number>       setting gpu number, default 4"
        echo "-n, --nodes <number>      setting node number, default 1"
        echo "-s, --submit                      auto submit, default false"
        echo "-h, --help                        show this help"
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
#SBATCH --partition=gp1d
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

SIF=/home/nakiri5500/hpl/hpc-benchmarks:21.4.sif

MPI=pmi2
HPL="/workspace/hpl.sh"
DAT="--dat ./datas/V100_${NUM_NODES}node_${NUM_GPUS}GPU.dat"
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
# singularity --mpi=\$MPI run --nv \$SIF \$MPI \$MPI_ARG \$DAT \$CPU \$CPUpRANK \$GPU
EOF

echo "Generate ${SLURM_SCRIPT}"
if [ "$AUTO_SUBMIT" = true ]; then
        sbatch ${SLURM_SCRIPT}
fi