## Microbench

### Download bench

```shell
git clone https://github.com/yulistic-benchmarks/FS_microbench.git micro
git checkout d38958d
```

### Set proper configurations in the script files

- `E2FSPROG_PATH` in `scripts/format.sh`
- `MOUNT_PATH`, `DEV_PATH`, and other configurations in `scripts/zj_main.sh`
- Configurations in `micro/scripts/run_tput_all.sh`

### Run bench

```shell
cd scripts
./zj_main.sh
```

FYI, `scripts/zj_main.sh` sources `micro/scripts/run_tput_all.sh`.
