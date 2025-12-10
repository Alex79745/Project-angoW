locals {
  masters = {
    "talos-master-1" = { vmid = 101; cores = 2; memory = 2048; disk = 20; }
    "talos-master-2" = { vmid = 102; cores = 2; memory = 2048; disk = 20; }
    "talos-master-3" = { vmid = 103; cores = 2; memory = 2048; disk = 20; }
  }

  workers = {
    "talos-worker-1" = { vmid = 201; cores = 2; memory = 2048; disk = 20; }
    "talos-worker-2" = { vmid = 202; cores = 2; memory = 2048; disk = 20; }
  }
}
