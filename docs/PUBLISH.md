# 发布到远端（GitHub / Gitee / 自建）

## 当前状态（已就绪，只差远端仓库）

- `origin` 已预置为 `git@github.com:Vladivostok1017/vangogh-kernel-ksu.git`
- 本机 SSH key 已验证可登录 GitHub，身份 `Vladivostok1017`
  （`ssh -T git@github.com` → `Hi Vladivostok1017! You've successfully authenticated`）
- 工作区干净，3 个提交，206 个文件，pack 后 180 MiB
- 该仓库**尚未在 GitHub 上创建**，所以 `git push` 现在报 `ERROR: Repository not found.`

**只差一步**：在 GitHub 网页 New repository → 名字填 `vangogh-kernel-ksu` →
**不要**勾 README/.gitignore/license → Create。然后：

```bash
cd F:\vangogh-kernel-ksu
git push -u origin main
```

（若想换个仓库名，先 `git remote set-url origin git@github.com:Vladivostok1017/<新名字>.git`。）

---

仓库里已经写好 `.gitignore` 和 `.gitattributes`，`artifacts/` 与 `backup/` 下的二进制
全部以 `xz` 存放，**最大单文件 65.6 MiB（`modem.img.xz`）**，低于 GitHub 的 100 MiB
硬限制，因此直接 `git push` 就行，不需要 LFS。

总量约 190 MiB（其中 `backup/` 约 117 MiB、`artifacts/` 约 73 MiB）。首次推送会比较慢。

## 1. 建空仓库

GitHub 网页 → New repository → **不要**勾选 "Add a README / .gitignore / license"
（否则远端会有提交，需要先 `pull --rebase`）。

## 2. 关联并推送

```bash
cd vangogh-kernel-ksu

git remote add origin https://github.com/<USER>/<REPO>.git
git branch -M main
git push -u origin main
```

用 SSH 的话把 URL 换成 `git@github.com:<USER>/<REPO>.git`。

## 3. 单个 HTTP 请求体太大 / 超时

190 MiB 一次推不上去时，分批推（先把大对象单独推一轮）：

```bash
# 提高 post buffer，避免 HTTP 413
git config http.postBuffer 524288000

# 或者先用小批量把历史骨架推上去，再补大文件
git push -u origin main
# 失败就退回重试，git 会复用已确认的对象
git push -u origin main
```

也可以用浅推送把当前快照推上去（丢掉历史，仓库仍是完整的）：

```bash
git checkout --orphan snapshot
git add -A
git commit -m "snapshot: complete tree"
git push -u origin snapshot:main
```

## 4. 之后想改用 Git LFS

二进制已经在库里了，迁 LFS 需要重写历史：

```bash
git lfs install
git lfs track "*.xz" "*.apk" "*.ko"
git add .gitattributes
git lfs migrate import --include="*.xz,*.apk,*.ko" --everything
git push --force origin main
```

> GitHub 免费额度是 1 GB 存储 + 1 GB/月流量，190 MiB 在额度内；但如果被大量克隆，
> 流量会烧得很快。对访问量大的项目，把这些文件放到 Release 附件里更合适
> （`artifacts/`、`backup/` 保持原样即可，Release 只是额外挂一份）。

## 5. 推之前的自检

```bash
git status --short                 # 应为空
git fsck --no-progress             # 无 dangling/报错
git count-objects -vH              # size-pack 心里有数
git ls-files -s | wc -l            # 文件数
find . -path ./.git -prune -o -type f -size +95M -print   # 应为空
```

Windows 下等价检查：`git ls-files -s | Measure-Object -Line`，以及

```powershell
Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notlike '*\.git\*' -and $_.Length -gt 95MB }
```
