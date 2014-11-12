args@{ lib, ... }:

let ec2 = import ./ec2-info.nix args;
in
{
  resources.machines.centos = {
    deployment.ec2 = ec2.args // {
      instanceType = "m3.medium";
      ami = ec2.amis.eu-west-1.centos64-hvm;
    };
    deployment.nix = false;
  };
}
