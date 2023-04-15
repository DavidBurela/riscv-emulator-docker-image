FROM debian:11
EXPOSE 2222

# Install all needed packages
RUN apt-get update && \
apt-get install -y --no-install-recommends ca-certificates git wget build-essential ninja-build libglib2.0-dev libpixman-1-dev u-boot-qemu unzip libslirp-dev && \
# clean up the temp files
apt-get autoremove -y && \
apt-get clean && \
rm -rf /var/lib/apt/lists/*

# Download and configure QEMU
WORKDIR "/root"
RUN git clone https://github.com/qemu/qemu && \ 
mkdir /root/qemu/build  && cd /root/qemu/build && \
# build and install
../configure --target-list=riscv64-softmmu && make -j3 && make install && \
# clean up the git repo and build artifacts after installed
rm /root/qemu -r

# Get RISC-V Debian image
WORKDIR "/root"
RUN wget https://gitlab.com/api/v4/projects/giomasce%2Fdqib/jobs/artifacts/master/download?job=convert_riscv64-virt -O artifacts.zip && \
unzip artifacts.zip && rm artifacts.zip

CMD qemu-system-riscv64 -smp 2 -m 2G -cpu rv64 -nographic -machine virt -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf -device virtio-blk-device,drive=hd -drive file=artifacts/image.qcow2,if=none,id=hd -device virtio-net-device,netdev=net -netdev user,id=net,hostfwd=tcp::2222-:22 -object rng-random,filename=/dev/urandom,id=rng -device virtio-rng-device,rng=rng -append "root=LABEL=rootfs console=ttyS0"
