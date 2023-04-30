# Install OKD/OCP cluster on AWS with Agnostic Platform (None) BYO LB

!!! warning "TODO / WIP page"
    This page is not completed!


Goal:

- Exercise how to provide your own Load Balancer using platform agnostic


## Stacks

(... Network, DNS, IAM..)

### Load Balancer Stack (external)

External Load Balancer alternatives when deploying agnostic clusters in AWS provider.

#### HAProxy and Keepalived (alternative)

- Create EC2 Instances to run HAProxy

> TODO create two EC2 on public subnets

- Register the DNS of those instances

> Create entries on DNS to master-{0-2}.<cluster_domain>

- Install external Load Balancers

> TODO: Install HAProxy and keepalived on new EC2

References:

- https://docs.openshift.com/container-platform/4.11/installing/installing_vsphere/installing-vsphere-installer-provisioned-customizations.html#nw-osp-configuring-external-load-balancer_installing-vsphere-installer-provisioned-customizations
- https://docs.openshift.com/container-platform/4.11/installing/installing_vsphere/installing-vsphere.html#installation-load-balancing-user-infra_installing-vsphere

#### HAProxy and EC2 Service Discovery (alternative)

> TODO: alternative

References:

- https://medium.com/@sudhindrasajjal/autoscaling-your-ec2-instances-using-haproxy-and-consul-5d2bc9ebafdb
- https://www.haproxy.com/blog/aws-ec2-service-discovery-with-haproxy/
- https://github.com/gavsmi/haproxy-ec2-auto-discover
- https://www.youtube.com/watch?v=ZvKPAug-IgA

#### NGINX (alternative)

> TODO

#### Traefik (alternative)

> TODO

#### Kong (alternative)

> TODO

#### Apache (alternative)

> TODO
