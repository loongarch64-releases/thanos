#!/bin/bash
set -exuo pipefail

UPSTREAM_OWNER=thanos-io
UPSTREAM_REPO=thanos
VERSION="${1}"
echo "   🏢 Org:   ${UPSTREAM_OWNER}"
echo "   📦 Proj:  ${UPSTREAM_REPO}"
echo "   🏷️  Ver:   ${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DISTS="${ROOT_DIR}/dists"
SRCS="${ROOT_DIR}/srcs"

# ======================================================================

PATCHES="${ROOT_DIR}/patches"
BUILD_DIR="${SRCS}/${VERSION}"
DIST_DIR="${DISTS}/${VERSION}"

mkdir -p "${DISTS}/${VERSION}" "${SRCS}"

# ==========================================
# 👇 用户自定义构建逻辑 (示例)
# ==========================================

echo "🔧 Compiling ${UPSTREAM_OWNER}/${UPSTREAM_REPO} ${VERSION}..."

# 1. 准备阶段：安装依赖、下载代码、应用补丁等
prepare()
{
    echo "📦 [Prepare] Setting up build environment..."
    
    rm -rf ${BUILD_DIR}
    git clone -b ${VERSION} --depth=1 https://github.com/thanos-io/thanos ${BUILD_DIR}
    
    echo "✅ [Prepare] Environment ready."
}

# 2. 编译阶段：核心构建命令
build()
{
    echo "🔨 [Build] Compiling source code..."
    
    # thanos 官方用 promu 构建，--prefix 直接指定二进制输出目录
    # 注意：不要用 `make build`，其依赖 check-git (应用补丁后 worktree 变脏会失败) 和 deps (go mod tidy 弄脏 go.mod/go.sum)
    (
        cd ${BUILD_DIR}
        shopt -s nullglob
        local_patches=(${PATCHES}/*.patch)
        shopt -u nullglob
        [ ${#local_patches[@]} -gt 0 ] && git apply "${local_patches[@]}"
        promu build -v --prefix ${DIST_DIR}
        # promu tarball 从二进制目录打包，命名: thanos-<version>.<GOOS>-<GOARCH>.tar.gz
        # 版本取自上游 VERSION 文件或 git describe；不带 --prefix 时输出到当前目录
        promu tarball ${DIST_DIR}
    )

    echo "✅ [Build] Compilation finished."
}

# 3. 后处理阶段：整理产物
post_build()
{
    echo "📦 [Post-Build] Organizing artifacts..."
    
    # 将 tar.gz 移入产物目录，最终只需 tar.gz，删除裸二进制
    mv ${BUILD_DIR}/thanos-*.tar.gz ${DIST_DIR}/
    rm -f ${DIST_DIR}/thanos

    echo "✅ [Post-Build] Artifacts ready in ./dists/${VERSION}."
}

# 主入口
main()
{
    prepare
    build
    post_build
}

main

# ==========================================
# 👆 自定义逻辑结束
# ==========================================

cat > "${DISTS}/${VERSION}/release.txt" <<EOF
Project: ${UPSTREAM_REPO}
Organization: ${UPSTREAM_OWNER}
Version: ${VERSION}
Build Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "✅ Compilation finished."
ls -lh "${DISTS}/${VERSION}"
