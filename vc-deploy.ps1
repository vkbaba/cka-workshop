# Count current sessions 
$session = $(kubectl get workshopsession -o=jsonpath='{.items[*].metadata.name}').Split(" ")
$env = $(kubectl get workshopenvironment -o=jsonpath='{.items[*].metadata.name}').Split(" ")
if ($env.length > 1) {
    Write-Host "Only one workshop environment is acceptable"
    exit
}
$pod = $(kubectl get pod -n $env -o=jsonpath='{.items[*].metadata.name}').Split(" ")

for($i = 0; $i -le $session.length - 1; $i++) {
    $vc_name = $session[$i]
    $pod_name = $pod[$i]
    vcluster create vc-$vc_name -n vc-$vc_name --expose -f values.yaml --connect
    kubectl cp -n $env .\kubeconfig.yaml ${pod_name}:/home/eduk8s/.kube/config 
    rm .\kubeconfig.yaml
}
