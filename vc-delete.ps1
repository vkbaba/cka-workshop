# Count current sessions 
$session = $(kubectl get workshopsession -o=jsonpath='{.items[*].metadata.name}').Split(" ")

for($i = 0; $i -le $session.length - 1; $i++) {
    $vc_name = $session[$i]
    vcluster delete vc-$vc_name -n vc-$vc_name
}