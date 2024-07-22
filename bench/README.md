## Microbench

### Download bench

```shell
git clone https://github.com/yulistic-benchmarks/FS_microbench.git micro
# or
git clone https://github.com/yulistic-benchmarks/filebench.git
```

### Set proper configurations in the script files

- `E2FSPROG_PATH` in `scripts/format.sh`
- `MOUNT_PATH`, `DEV_PATH`, and other configurations in `scripts/XXXX_zj_main.sh`
- Configurations in `micro/scripts/run_tput_all.sh`, `filebench/scripts/run_all.sh`, and so on.

### Run bench

```shell
cd scripts
./filebench_zj_main.sh
```
You can run the other benchmarks in the same way.

FYI, `scripts/filebench_zj_main.sh` sources `filebench/scripts/run_all.sh`.
