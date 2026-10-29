"""Render the local release packet without external libraries or network calls."""
from pathlib import Path
import html, re, base64
root=Path(__file__).resolve().parents[1]/'docs/release-v1'
files=['README.md','01-product.md','02-prototype.md','03-technical.md','04-release.md','05-implementation.md','06-assets.md','07-release-gaps.md','08-visual-v2.md','09-repair-visual-audit.md']
labels=['资料总览','产品方案','交互规范','技术方案','上线验收','实施报告','素材记录','发布缺项','视觉升级','Repair visual audit']

def inline(text):
    text=html.escape(text)
    text=re.sub(r'`([^`]+)`',r'<code>\1</code>',text)
    text=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',text)
    def link(match):
        title,url=match.groups()
        if url in files: url='#section-'+str(files.index(url))
        return f'<a href="{url}">{title}</a>'
    return re.sub(r'\[([^\]]+)\]\(([^)]+)\)',link,text)

def render(source):
    out=[];table=False;code=False;listing=False
    for line in source.splitlines():
        if line.startswith('```'):
            code=not code;out.append('<pre><code>' if code else '</code></pre>');continue
        if code:out.append(html.escape(line)+'\n');continue
        if not line.startswith('|') and table:out.append('</tbody></table></div>');table=False
        if not re.match(r'^(- |\d+\. )',line) and listing:out.append('</ul>');listing=False
        if not line.strip():continue
        if line.startswith('!['):
            path=root/'assets/Lirtrilner-Clockwork-prototype-v1.png'
            out.append('<img alt="设计参考原型，不是运行截图" src="data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode()+'">');continue
        if line.startswith('|'):
            if re.match(r'^\|[\s:|\-]+$',line):continue
            values=line.strip('|').split('|')
            tag='td' if table else 'th'
            if not table:out.append('<div class="table-wrap"><table><tbody>');table=True
            out.append('<tr>'+''.join(f'<{tag}>{inline(v.strip())}</{tag}>' for v in values)+'</tr>');continue
        if line.startswith('#'):
            n=len(line)-len(line.lstrip('#'));out.append(f'<h{n}>{inline(line[n:].strip())}</h{n}>');continue
        if re.match(r'^(- |\d+\. )',line):
            if not listing:out.append('<ul>');listing=True
            out.append('<li>'+inline(re.sub(r'^(- |\d+\. )','',line))+'</li>');continue
        out.append('<p>'+inline(line)+'</p>')
    if table:out.append('</tbody></table></div>')
    if listing:out.append('</ul>')
    return '\n'.join(out)

css='''*{box-sizing:border-box}body{margin:0;color:#35271f;background:#f3eadc;font:16px/1.8 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}aside{position:fixed;width:210px;inset:0 auto 0 0;padding:30px 22px;background:#35271f;color:#fff7e8}aside a{display:block;color:#fff7e8;padding:9px 0}main{margin-left:210px;padding:32px;max-width:1400px}section,header{background:#fffaf1;padding:28px 34px;border-radius:20px;margin-bottom:24px}h1{line-height:1.4}h2{margin-top:32px;border-top:1px solid #dbcbb8;padding-top:20px}a{color:#a63827}img{max-width:100%;border-radius:16px}.table-wrap{overflow:auto}table{border-collapse:collapse;font-size:14px;width:100%}td,th{padding:10px;border:1px solid #dbcbb8;text-align:left;vertical-align:top}th{background:#efe2cf}pre{white-space:pre-wrap;word-break:break-word;background:#eee5d8;padding:16px;border-radius:12px}code{font-size:.88em}.status{border-left:4px solid #b73e2b;padding:12px;background:#faebd8}@media(max-width:850px){aside{position:static;width:auto}aside nav{display:flex;flex-wrap:wrap;gap:12px}main{margin:0;padding:12px}section{padding:20px}}'''
nav=''.join(f'<a href="#section-{i}">{i+1:02} {label}</a>' for i,label in enumerate(labels))
body=''.join(f'<section id="section-{i}">{render((root/file).read_text())}</section>' for i,file in enumerate(files))
page=f'<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>发条修理铺 · 实施与上线资料</title><style>{css}</style><aside><h2>发条修理铺</h2><nav>{nav}</nav></aside><main><header><h1>发条修理铺 · 1.0</h1><p>2026-10-29 · 完整离线资料</p><p class="status">核心实现、66 题重放和未签名归档已完成。真机、触摸/辅助功能、真人试玩、性能与发布资料仍待验收。未提交审核。</p><a href="verification/index.html">浏览真实页面渲染核验</a></header>{body}</main></html>'
(root/'Lirtrilner-Release-Overview.html').write_text(page)
# Gallery uses the original render files; no generated or composited app screenshot.
sections=[]
for device in ['repair-v4-iphone17pro','repair-v4-iphone-se3','parts-v3-iphone17pro','parts-v3-iphone-se3','visual-v2-iphone17pro','visual-v2-iphone-se3','iphone17pro','iphone-se3']:
    images=sorted((root/'verification'/device).glob('*.png'))
    figures=''.join(f'<figure><a href="{device}/{p.name}"><img loading="lazy" src="{device}/{p.name}" alt="{p.stem}"></a><figcaption>{p.stem}</figcaption></figure>' for p in images)
    sections.append(f'<h2>{device}</h2><div class="grid">{figures}</div>')
(root/'verification/index.html').write_text('<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>发条修理铺 · 页面渲染核验</title><style>body{font:16px/1.6 -apple-system,sans-serif;background:#fff7e8;color:#35271f;margin:24px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:20px}figure{margin:0}img{width:100%;border:1px solid #dfc3a1;border-radius:18px}figcaption{padding:8px}a{color:#b73e2b}</style><h1>真实 UIKit 页面 · 中英文渲染检查</h1><p>新版视觉 v2：54 个状态 × 2 种模拟器尺寸；下方保留旧版 52 个状态供对比。Debug 核验入口使用引擎重放生成合法局面，不模拟触摸，不写入玩家存档。图片不含系统状态栏，不是正式商店截图；零布局歧义不代表所有交互或大字均通过。</p><p><a href="../05-implementation.md">实施报告</a> · <a href="../07-release-gaps.md">发布缺项</a></p>'+''.join(sections)+'</html>')
print('Updated offline overview and render gallery.')
