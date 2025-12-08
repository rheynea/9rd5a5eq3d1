#!/bin/bash
 
# This file will be sourced in init.sh
 
# https://raw.githubusercontent.com/ai-dock/comfyui/main/config/provisioning/default.sh
 
# Packages are installed after nodes so we can fix them...
 
DEFAULT_WORKFLOW="https://raw.githubusercontent.com/Norby123/nord-F1d-VastAI/refs/heads/main/FLUX_for_VastAI.json"
 
APT_PACKAGES=(
    "aria2"
)
 
PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)
 
NODES=(
    	"https://github.com/willmiao/ComfyUI-Lora-Manager"
     
)
 
CHECKPOINT_MODELS=(
     #PONY 6
    "https://civitai.com/api/download/models/290640?type=Model&format=SafeTensor&size=pruned&fp=fp16"
    #PERFECT PONY 6XL
    "https://civitai.com/api/download/models/2114187?type=Model&format=SafeTensor&size=pruned&fp=fp16"
    #CYBER PONY
    "https://civitai.com/api/download/models/2334591?type=Model&format=SafeTensor&size=full&fp=fp32"
    #waiIllustriousSDXL_v110
    "https://civitai.com/api/download/models/1410435?type=Model&format=SafeTensor&size=pruned&fp=fp16"
    #Pony 7
    "https://huggingface.co/purplesmartai/pony-v7-base/resolve/main/safetensor/pony-v7-base.safetensors"
)
 
UNET_MODELS=(

)
 
LORA_MODELS=(
     #PONY - CONCEPT ART ULTIMATUM
     "https://civitai.com/api/download/models/418782?type=Model&format=SafeTensor"
     #PONY - VIXON - Gothic neon
     "https://civitai.com/api/download/models/398847?type=Model&format=SafeTensor"
     #Cardinal of Sin's Thessics Style (Illustrious)
     "https://civitai.com/api/download/models/1400602?type=Model&format=SafeTensor"
     
     
)
 
VAE_MODELS=(
   "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors"
  	"https://huggingface.co/NorbyXL/vae/resolve/main/ponyStandardVAE_v10.safetensors"
  	"https://huggingface.co/NorbyXL/vae/resolve/main/vae-ft-MSE(picivel_jobb)-840000-ema-pruned.ckpt"
   "https://huggingface.co/purplesmartai/pony-v7-base/resolve/main/vae/diffusion_pytorch_model.fp16.safetensors"
)
 
ESRGAN_MODELS=(
    "https://huggingface.co/Phips/4xNomosWebPhoto_RealPLKSR/resolve/main/4xNomosWebPhoto_RealPLKSR.safetensors"
   	"https://github.com/Phhofm/models/releases/download/4xNomosWebPhoto_RealPLKSR/"
   	"https://github.com/Phhofm/models/releases/download/4xNomosWebPhoto_RealPLKSR/4xNomosWebPhoto_RealPLKSR.pth"
)
 
CONTROLNET_MODELS=(
 
)
 
### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###
 
function provisioning_start() {
    if [[ ! -d /opt/environments/python ]]; then 
        export MAMBA_BASE=true
    fi
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh comfyui
 
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_default_workflow
    provisioning_lora_folders
    provisioning_get_nodes
    provisioning_get_pip_packages
    provisioning_get_models \
        "${WORKSPACE}/ComfyUI/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/ComfyUI/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/ComfyUI/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/ComfyUI/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/ComfyUI/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/ComfyUI/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    provisioning_print_end
}
 
function pip_install() {
    if [[ -z $MAMBA_BASE ]]; then
            "$COMFYUI_VENV_PIP" install --no-cache-dir "$@"
        else
            micromamba run -n comfyui pip install --no-cache-dir "$@"
        fi
}
 
function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}
 
function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip_install ${PIP_PACKAGES[@]}
    fi
}
 
function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="/opt/ComfyUI/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                   pip_install -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip_install -r "${requirements}"
            fi
        fi
    done
}
 
function provisioning_get_default_workflow() {
    if [[ -n $DEFAULT_WORKFLOW ]]; then
        workflow_json=$(curl -s "$DEFAULT_WORKFLOW")
        if [[ -n $workflow_json ]]; then
            echo "export const defaultGraph = $workflow_json;" > /opt/ComfyUI/web/scripts/defaultGraph.js
        fi
    fi
}
 
function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}
 
function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}
 
function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}
 
function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"
 
    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")
 
    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}
 
function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"
 
    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")
 
    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}
 
# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif 
        [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        final_url=$(curl -H "Authorization: Bearer $auth_token" -s -L -I -w '%{url_effective}' -o /dev/null "$1")
        filename=$(curl -H "Authorization: Bearer $auth_token" -s -L -I "$final_url" | grep -i 'content-disposition' | sed -n 's/.*filename\*=UTF-8''//;s/.*filename="//;s/";//p')
        aria2c -x 16 -s 16 -k 10M -c --file-allocation=falloc --header="Authorization: Bearer $auth_token" --dir="$2" -o "$filename" "$final_url"
    elif 
        [[ -n $auth_token && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        final_url=$(curl -H "Authorization: Bearer $auth_token" -s -L -I -w '%{url_effective}' -o /dev/null "$1")
        aria2c -x 16 -s 16 -k 10M -c --file-allocation=falloc --dir="$2" "$final_url"
    fi
}
 
provisioning_start
 
