OP-TEE 入門
===========

[OP-TEE](https://optee.readthedocs.io) の Repository を Build して QEMU v7 を実行します

Ubuntu 以外の OS から作業をする
-------------------------------

Docker で Build をするために基本的に Host の OS はあまり関係してきませんが Uubuntu 以外の OS で実行するかつ Volume を Bind する場合は Disk format が Case-sensitive か気をつける必要があります。

macOS の場合 Case-insensitive が標準なため、もし Code を Host 上で管理して Bind して Docker container で読ませたい場合 Disk Utility で Case-sensitive な Disk image を作成し、その中で管理する必要があります。設定の例として

| key          | value                                 |
|:------------ |:------------------------------------- |
| Name         | op-tee                                |
| Size         | 500 GB                                |
| Format       | APFS (Case-sensitive)                 |
| Encryption   | none                                  |
| Partitions   | Single partition - GUID Partition Map |
| Image Format | sparse bundle disk image              |

といったパラメーターで作成します。  
お好みで mount 後に Spotlight の検索から除外するよう設定します。

sparsebundle のサイズが 10GB 以上となるため NAS 上に sparsebundle を置いて mount して作業したいかもしれませんが、それをすると IO error が発生するため、作業をする際は rsync で sparsebundle を local に持ってきて実行し、作業が終わったら NAS に転送する、といった運用が必要になります。

```bash
# pull
rsync -crltvhiP <path to nas>/op-tee.sparsebundle .

# push
rsync -crltvhiP op-tee.sparsebundle <path to nas>
```

Docker container の起動
-----------------------

Android / OP-TEE / QEMU を Build するための環境を GitHub Container Registry に push したのでそれを使用します。

また、お好みで Docker container に .bashrc や .inputrc や .gitconfig を bind します。

次の Command は現在のディレクトリを作業ディレクトリとして Bind します。作業ディレクトリには Ccache 用のディレクトリや OP-TEE のコードを置きます。

```bash
# on host pc.

# https://github.com/users/sukawasatoru/packages/container/package/op-tee
docker pull ghcr.io/sukawasatoru/op-tee:1.0

cd <path to work dir>
mkdir -p .ccache files
touch files/{.bash_history,.gitconfig.local}

docker run --name op-tee -it \
  --mount type=bind,src=$HOME/.bashrc,dst=/root/.bashrc,readonly \
  --mount type=bind,src=$HOME/.inputrc,dst=/root/.inputrc,readonly \
  --mount type=bind,src=$HOME/.gitconfig,dst=/root/.gitconfig,readonly \
  --mount type=bind,src=$PWD/files/.gitconfig.local,dst=/root/.gitconfig.local \
  --mount type=bind,src=$PWD/files/.bash_history,dst=/root/.bash_history \
  --mount type=bind,src=$PWD/.ccache,dst=/root/.ccache \
  --mount type=bind,src=$PWD,dst=/work \
  -w/work \
  ghcr.io/sukawasatoru/op-tee:1.0
```

Docker container の初期設定
---------------------------

初めて作業ディレクトリを作成し Docker container を実行する場合は OP-TEE のコードを `repo sync` したり Toolchains をダウンロードし設定必要があります。

```bash
# in docker container

# https://optee.readthedocs.io/en/latest/building/gits/build.html#step-4-get-the-toolchains
# https://optee.readthedocs.io/en/latest/building/toolchains.html
# https://github.com/OP-TEE/build/blob/master/toolchain.mk
# for cache toolchains.
mkdir -p toolchains
cd /work/toolchains
[[ ! -f gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz ]] && curl -fSLO https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
[[ ! -f gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz ]] && curl -fSLO https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz
mkdir -p /work/toolchains/aarch{32,64}
tar -xf gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz -C /work/toolchains/aarch32 --strip-components=1
cd /work/toolchains/aarch32/bin && for f in *-none-linux*; do ln -s $f ${f//-none} ; done && cd -
tar -xf gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz -C /work/toolchains/aarch64 --strip-components=1
cd /work/toolchains/aarch64/bin && for f in *-none-linux*; do ln -s $f ${f//-none} ; done && cd -

# https://optee.readthedocs.io/en/latest/building/devices/qemu.html
# https://optee.readthedocs.io/en/latest/building/gits/build.html#step-3-get-the-source-code
mkdir /work/src
cd /work/src
repo init -u https://github.com/OP-TEE/manifest.git
# if running under the proxy environment, need to rewrite manifest:
# .repo/manifests/default.xml `https://gitlab.denx.de/u-boot` to `https://github.com/u-boot`

cd /work/src
repo sync -j32 --no-clone-bundle

# https://optee.readthedocs.io/en/latest/building/gits/build.html#step-4-get-the-toolchains
ln -s /work/toolchains /work/src/toolchains
```

Build
-----

ここまで問題なく実行できたら OP-TEE を Build することができます。

MacBook Pro 13-inch, 2020, 2.3 GHz Core i7, 32 GB RAM の場合は初回ビルドに 4時間程度かかっていると思われるので気長に待つ。

```bash
# if reuse "/work/src" on the new environment (after the "repo forall -c git clean -fdx")
# then execute the following command:
# repo sync -j32 -l

# https://optee.readthedocs.io/en/latest/building/gits/build.html#step-5-build-the-solution
cd /work/src/build
make -j$(($(nproc) + 1))
```

Run
---

Build に成功したら QEMU を実行することができます。 Ubuntu の GUI の Terminal から実行した場合は Normal World と Secure World の Terminal が自動で開くので問題ありませんが GUI のない環境 (今回の Docker container) では自分で Normal World と Secure World の Terminal を準備する必要があります。

```bash
# on host pc #1 (main).
# "docker run" or "docker start".

# on host pc #2 (Normal World).
docker exec -it op-tee /work/src/soc_term/soc_term 54320

# on host pc #3 (Secure World).
docker exec -it op-tee /work/src/soc_term/soc_term 54321

# in docker container #1 (main).
make -j$(($(nproc) + 1)) run
# launched the qemu.
c
```

Clean
-----

Ccache 以外の生成物を削除したい場合は次の Command を実行します:

```bash
cd <path to work>/src
repo forall -c git clean -fdx
repo sync -lj32
rm -rf out{,-br}
```
