#!/usr/bin/env bash

{
  find /host/run -name docker.sock -exec ln -sf /host/run/docker.sock /var/run/docker.sock \;
  ln -sf /apps/data/workspace/w.code-workspace /root/w.code-workspace

}
