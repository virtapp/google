gcloud container clusters create ${GCLOUD_K8S_CLUSTER} \
--create-subnetwork name=${GCLOUD_K8S_CLUSTER} \
--enable-ip-alias \
--enable-private-nodes \
--master-ipv4-cidr 172.16.0.0/28 \
--machine-type=e2-standard-4  \
--min-nodes=0                                   `# minimum 0 nodes` \
--max-nodes=8                                   `# maximum 10 nodes` \
--num-nodes=2                                   `# start from 1 node` \
--enable-autoscaling                            `# use autoscaling` \
--labels=environment=${GCLOUD_ENV_NAME}         `# set environment label` \
--enable-master-authorized-networks \
--master-authorized-networks 0.0.0.0/0 \
--no-enable-basic-auth \
--no-issue-client-certificate \
--scopes=storage-rw,service-control \
--node-version=${GCLOUD_K8S_VERSION}
sleep 5

       echo   "----- ..................................................... -----"
       echo   "----- .... CREATE-DATA-POOL-${GCLOUD_K8S_CLUSTER} ....... -----"
       echo   "----- ..................................................... -----"
  
gcloud container node-pools create data-pool \
--zone=${GCLOUD_REGION}                                  `# specify zone` \
--project=${GCLOUD_PROJECT}                              `# specify project` \
--cluster=${GCLOUD_K8S_CLUSTER}                          `# specify clusster` \
--machine-type=e2-standard-4                             `# use n1-standard-4 (4 vCPU, 15 GB) machine` \
--min-nodes=1                                            `# minimum 1 nodes` \
--max-nodes=1                                            `# maximum 1 nodes` \
--num-nodes=2                                            `# start from 1 node` \
--max-pods-per-node=25                                   `# limit the number of pods per node to limit IP allocation` \
--node-labels=environment=${GCLOUD_ENV_NAME}             `# set environment and target labels` \
--node-version=${GCLOUD_K8S_VERSION}                     `# specify node kube agent version` \
--scopes=storage-rw,service-control 

sleep 5
gcloud services enable servicenetworking.googleapis.com --project=${GCLOUD_PROJECT}
sleep 5

        echo   "----- ..................................................... -----"
        echo            "----- .... CREATE-DOCKER-REGISTRY ....... -----"
        echo   "----- ..................................................... -----"      

kubectl create secret docker-registry regcred \
--docker-username=agentvidockerdeploy \
--docker-password=4gentVI% \
--docker-email=docker-deploy@artlist.io
sleep 5

           echo   "----- ..................................................... -----"
           echo          "----- .... CREATE-ROLE-${GCLOUD_USER} ....... -----"
           echo   "----- ..................................................... -----"  
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=${GCLOUD_USER}
           echo   "----- ..................................................... -----"
           echo    "----- .... CLUSTER-${GCLOUD_K8S_CLUSTER}-COMPLETE ....... -----"
           echo   "----- ..................................................... -----"
sleep 450


           echo   "----- ..................................................... -----"
           echo                "----- .... HELM-ADD-REPO ....... -----"
           echo   "----- ..................................................... -----"
           
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo add stable https://charts.helm.sh/stable || true
helm repo add allegroai https://allegroai.github.io/clearml-helm-charts || true
helm repo update && helm repo ls
helm install clearml-server allegroai/clearml -n clearml --create-namespace
  echo      Waiting for all pods in running mode:
until kubectl wait --for=condition=Ready pods --all -n clearml; do
sleep 5
done  2>/dev/null
kubectl get pods -A | grep clearml && kubectl get svc
           echo   "----- ..................................................... -----"
           echo                 "----- .... COMPLETE ....... -----"
           echo   "----- ..................................................... -----"
