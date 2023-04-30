# https://diagrams.mingrammer.com/docs/nodes/aws
from diagrams import Cluster, Diagram, Edge
from diagrams.custom import Custom
from urllib.request import urlretrieve

openshift_url = "https://upload.wikimedia.org/wikipedia/commons/3/3a/OpenShift-LogoType.svg"
openshift_icon = "/tmp/icon-openshift.png"
urlretrieve(openshift_url, openshift_icon)

k8s_url = "https://upload.wikimedia.org/wikipedia/commons/3/39/Kubernetes_logo_without_workmark.svg"
k8s_icon = "/tmp/icon-k8s.png"
urlretrieve(k8s_url, k8s_icon)

DIAGRAMS_PATH="./images"
DIAGRAMS_PREFIX="example"
DIAGRAM_BASE_NAME=f"{DIAGRAMS_PATH}/{DIAGRAMS_PREFIX}"

graph_attr = {}
DIAGRAM_NAME_BANNER=f"{DIAGRAM_BASE_NAME}"
with Diagram("Example Diagram",
            show=False, filename=DIAGRAM_NAME_BANNER,
            graph_attr=graph_attr):
 
    with Cluster("OpenShift Cluster"):
        k8s = Custom("", k8s_icon)
        ocp = Custom("", openshift_icon)

    k8s - ocp
