#!/usr/bin/env pwsh
# Run insecure deploy test and collect evidence
# Usage: open PowerShell in the repo root and run:
#   .\scripts\run_insecure_test.ps1

$evi = "evidence"
if (-not (Test-Path $evi)) { New-Item -ItemType Directory -Path $evi | Out-Null }

Write-Output "[1/7] Labeling namespace 'unifiapay' to enforce PodSecurity 'restricted' (will overwrite existing label)"
kubectl label --overwrite namespace unifiapay \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest 2>&1 | Tee-Object "$evi/label-namespace.txt"

Write-Output "[2/7] Saving insecure manifest copy to $evi/insecure-pod.yaml"
Copy-Item -Path "k8s/insecure-pod.yaml" -Destination "$evi/insecure-pod.yaml" -Force

Write-Output "[3/7] Attempting kubectl apply (normal) and capturing output"
kubectl apply -f k8s/insecure-pod.yaml 2>&1 | Tee-Object "$evi/insecure-deploy-apply.txt"

Write-Output "[4/7] Attempting server-side dry-run (server) and capturing output"
kubectl apply -f k8s/insecure-pod.yaml --server-side --dry-run=server 2>&1 | Tee-Object "$evi/insecure-deploy-dryrun.txt"

Write-Output "[5/7] Collecting get/describe (should report NotFound or similar)"
kubectl get pod insecure-deploy-test -n unifiapay 2>&1 | Tee-Object "$evi/insecure-deploy-getpod.txt"
kubectl describe pod insecure-deploy-test -n unifiapay 2>&1 | Tee-Object "$evi/insecure-deploy-describe.txt"

Write-Output "[6/7] Collecting recent events in namespace (useful to show rejection reason)"
kubectl get events -n unifiapay --sort-by='.metadata.creationTimestamp' 2>&1 | Tee-Object "$evi/insecure-deploy-events.txt"

Write-Output "[7/7] Capture RBAC check for current user and for the namespace default ServiceAccount"
kubectl auth can-i create pods -n unifiapay 2>&1 | Tee-Object "$evi/insecure-deploy-can-i.txt"
kubectl auth can-i create pods --as=system:serviceaccount:unifiapay:default -n unifiapay 2>&1 | Tee-Object "$evi/insecure-deploy-can-i-sa-default.txt"

Write-Output "`nDone. Evidence files written to: $evi`n"
Get-ChildItem $evi | ForEach-Object { Write-Output $_.FullName }

Write-Output "`nRecommendation for screenshots (Windows):
- Run this script in PowerShell so you see the live output.
- Screenshot 1: Terminal output showing the rejection message from 'kubectl apply' (also in $evi\insecure-deploy-apply.txt).
- Screenshot 2: Open $evi\insecure-deploy-events.txt in Notepad and capture the event lines that show the denial reason.
- Optional: capture $evi\insecure-deploy-dryrun.txt and the two can-i files for RBAC context.
"