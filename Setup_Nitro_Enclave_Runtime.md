## Setup Nitro Enclave Runtime

  https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave-cli-install.html
  

1. Create an EC2 instance with Nitro Enclave enabled. See [AWS documentation](https://docs.aws.amazon.com/enclaves/latest/user/create-enclave.html) for steps and requirement.

   Amazon Linux 2 AMI is recommended.

1. SSH into the instance. Install `nitro-cli`

   ```
   $ sudo amazon-linux-extras install aws-nitro-enclaves-cli
   $ sudo yum install aws-nitro-enclaves-cli-devel -y
   $ sudo usermod -aG ne $USER
   $ sudo usermod -aG docker $USER
   ```

1. Modify the preallocated memory for the enclave to 2048 MB.

   Modify the file `/etc/nitro_enclaves/allocator.yaml`, change the following line:

   ```
   # memory_mib: 512
   memory_mib: 2048
   ```

1. Enable Docker and Nitro Enclaves Allocator

   ```
   $ sudo systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
   $ sudo systemctl start docker && sudo systemctl enable docker
   ```

1. Reboot the instance

## Allocator configuration

In a Nitro Enclaves environment, the `memory_mib` parameter in `/etc/nitro_enclaves/allocator.yaml` is not the same as the ordinary “free” memory reported by tools like `free -h`. Please note the following important points:

1) `memory_mib` allocates HugePages (2 MiB pages)

- Enclaves allocate memory using 2 MiB huge pages (HugePages). The allocator reserves huge pages on the host and maps them into enclave address space.
- The RAM shown by `free -h` is ordinary memory and does not reflect hugepage availability. If HugePages are insufficient, `nitro-enclaves-allocator` will fail to configure memory and will not start.

Check hugepages with:

```bash
cat /proc/meminfo | grep Huge
```

If `HugePages_Free` is too small (compared to what `memory_mib` requires), then `memory_mib` is set too high for the current hugepage allocation.

2) You must reserve hugepages on the host

- The host must have enough 2 MiB huge pages reserved for the allocator to succeed. For example, to allocate 8 GiB to an enclave you need roughly:

```
8 GiB / 2 MiB = 4096 hugepages
```

3) Best practice

- Configure HugePages in a test environment and benchmark before production.

How to enable and persist hugepages

1. Check current `nr_hugepages`:

```bash
sudo cat /proc/sys/vm/nr_hugepages
```

If it prints `0`, hugepages are not yet reserved.

2. Temporarily set `nr_hugepages` (example: set 2048 pages):

```bash
sudo sysctl -w vm.nr_hugepages=2048
```

This sets the number of 2 MiB hugepages the kernel will reserve. You can confirm with:

```bash
grep Huge /proc/meminfo
```

You should see something like:

```
HugePages_Total:    2048
HugePages_Free:     2048
Hugepagesize:       2048 kB
```

3. Persist the setting across reboots by adding it to `/etc/sysctl.conf` (or better: a file in `/etc/sysctl.d/`):

```bash
echo "vm.nr_hugepages=2048" | sudo tee /etc/sysctl.d/99-nitro-hugepages.conf
sudo sysctl --system
```

4. Reboot (if required) and verify the value again:

```bash
sudo cat /proc/sys/vm/nr_hugepages
sudo grep Huge /proc/meminfo
```

To deactivate HugePages:

```bash
# Set nr_hugepages back to 0
sudo sysctl -w vm.nr_hugepages=0
# Remove your sysctl.d file if you added one
sudo rm -f /etc/sysctl.d/99-nitro-hugepages.conf
sudo sysctl --system
# Reboot if necessary
```

Troubleshooting allocator startup errors (E26 / E27 / E39)

- E26 (insufficient memory requested): the requested `memory` is less than the EIF minimum memory. Use `nitro-cli describe-eif --eif-path <file.eif>` to inspect EIF metadata and discover the minimum required memory.
- E27 (insufficient memory available): the allocator attempted to reserve the requested hugepages but the kernel could not satisfy the request. Ensure the host has enough free RAM and that `vm.nr_hugepages` is large enough.
- E39 (enclave process connection failure): often a consequence of previous errors; check `/var/log/nitro_enclaves` and the journal (`journalctl -u nitro-enclaves-allocator.service`) for detailed logs.

Example quick diagnostic steps:

```bash
# Show EIF minimum metadata
nitro-cli describe-eif --eif-path sparsity-enclave.eif

# Check hugepages availability
grep -i huge /proc/meminfo

# Show allocator config
sudo cat /etc/nitro_enclaves/allocator.yaml

# Try to increase nr_hugepages (example: set to 320 pages => 640 MiB)
sudo bash -c 'echo 320 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages' || true

# Update allocator.yaml memory_mib to match (e.g., 640)
sudo sed -i 's/^memory_mib:.*/memory_mib: 640/' /etc/nitro_enclaves/allocator.yaml

# Restart allocator
sudo systemctl restart nitro-enclaves-allocator.service
sudo systemctl status nitro-enclaves-allocator.service --no-pager -l

# If the allocator starts successfully, run the enclave
nitro-cli run-enclave --eif-path sparsity-enclave.eif --cpu-count 2 --memory 640 --debug-mode

# Check enclaves
nitro-cli describe-enclaves
```