const copy = {
  en: {
    skip:'Skip to content', navInstall:'Install', eyebrow:'A little clarity for your menu bar', headline:'Stay in flow.\nKnow your quota.', lede:'Your Codex quota and reset times, right where you need them. A small, native macOS app that stays out of your way.', download:'Download for Mac', source:'Explore the source ↗', compat:'v0.1.1 · macOS 13+ · Apple Silicon & Intel · MIT licensed', week:'Week', scene:'Less checking.\nMore creating.', sample:'Try it · sample data', plenty:'Plenty', low:'Getting low', almost:'Almost out', demoNote:'Interactive illustration, not a live account connection. No sign-in required on this website.', detailLabel:'SMALL APP. USEFUL DETAILS.', detailHeading:'Everything you need.\nNothing in the way.', f1title:'Both windows. One glance.', f1body:'See your remaining 5-hour and weekly quotas together, with a countdown or date for the next reset.', f2title:'A gauge that tells the story.', f2body:'The needle follows your 5-hour quota. Green above 50%, orange from 20–50%, and red below 20%.', f3title:'Native. Quiet. Open.', f3body:'Built with Swift and AppKit. No Python runtime, no telemetry service. English and Chinese, following your Mac.', installLabel:'UP AND RUNNING', installHeading:'Make room for\na little clarity.', installIntro:'Bring your existing Codex sign-in. CodexBar takes care of the glance.', release:'Release notes & checksum ↗', s1title:'Download and move', s1body:'Unzip the download and drag CodexBar.app into Applications. One universal build for both Mac architectures.', s2title:'Sign in to Codex', s2body:'Install Codex and sign in with ChatGPT. If needed, run codex login in Terminal. API-key usage is separate from subscription quota.', s3title:'Open and carry on', s3body:'Launch CodexBar. Quota refreshes every minute. Left-click to refresh or quit; right-click has no action.', noticeTitle:'A note on the first launch', noticeBody:'This release is ad-hoc signed, not Apple-notarized. If macOS blocks it and you trust the source, try opening it once, then choose Open Anyway in System Settings → Privacy & Security. You can also build from source.', openLabel:'YOURS TO MAKE YOUR OWN', openHeading:'Small enough to understand.\nOpen enough to extend.', openBody:'Read the code, build it yourself, or add the feature you have in mind. Contributions are welcome.', githubButton:'View on GitHub ↗', independent:'An independent open-source project. Not affiliated with OpenAI.'
  },
  zh: {
    skip:'跳至正文',navInstall:'安装',eyebrow:'菜单栏里，一点恰好的清晰',headline:'专注手头的事。\n额度，一眼便知。',lede:'Codex 剩余额度与重置时间，就在抬眼可见的地方。一个轻巧、原生、不打扰你的 macOS 菜单栏工具。',download:'下载 Mac 版',source:'查看开源代码 ↗',compat:'v0.1.1 · macOS 13+ · Apple Silicon 与 Intel · MIT 开源',week:'周',scene:'少一点查看。\n多一点创造。',sample:'试试看 · 示例数据',plenty:'额度充足',low:'额度偏低',almost:'即将耗尽',demoNote:'交互示意，未连接真实账号。浏览本网站无需登录。',detailLabel:'小工具，细节刚刚好。',detailHeading:'需要的，都在。\n多余的，都省了。',f1title:'两个周期，一眼看全。',f1body:'同时查看 5 小时和每周剩余额度，以及下次重置的倒计时或日期。',f2title:'不用细看，也能心中有数。',f2body:'指针随 5 小时剩余额度转动。高于 50% 为绿色，20–50% 为橙色，低于 20% 为红色。',f3title:'原生、安静，也开放。',f3body:'使用 Swift 与 AppKit 构建，无需 Python，没有遥测服务。中英文自动跟随 Mac 语言。',installLabel:'即刻开始',installHeading:'给菜单栏，\n留一点清晰。',installIntro:'沿用你的 Codex 登录状态，剩下的交给 CodexBar。',release:'版本说明与校验文件 ↗',s1title:'下载，拖入应用程序',s1body:'解压下载文件，将 CodexBar.app 拖入“应用程序”。同一个安装包支持两种 Mac 芯片架构。',s2title:'登录 Codex',s2body:'先安装 Codex 并通过 ChatGPT 登录。如有需要，在终端运行 codex login。API Key 用量与订阅额度不同。',s3title:'打开，继续你的工作',s3body:'启动 CodexBar，每分钟自动刷新额度。左键可立即刷新或退出，右键不响应。',noticeTitle:'首次打开的小提示',noticeBody:'此版本采用临时签名，未经 Apple 公证。如果 macOS 拦截，确认来源可信后先尝试打开一次，再到“系统设置 → 隐私与安全性”选择“仍要打开”。也可以自行从源码构建。',openLabel:'属于你，也由你定义',openHeading:'代码简洁，读得懂。\n完全开源，改得动。',openBody:'阅读代码、自行编译，或者加上你想要的功能。欢迎参与贡献。',githubButton:'在 GitHub 查看 ↗',independent:'独立开源项目，与 OpenAI 无隶属关系。'
  }
};
const languageButton = document.getElementById('language');
let lang = 'en';
try { if (localStorage.getItem('codexbar-language') === 'zh') lang = 'zh'; } catch {}
function renderLanguage() {
  document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
  document.querySelectorAll('[data-i18n]').forEach(element => {
    element.replaceChildren();
    copy[lang][element.dataset.i18n].split('\n').forEach((line,index) => {
      if (index) element.append(document.createElement('br'));
      element.append(document.createTextNode(line));
    });
  });
  languageButton.textContent = lang === 'en' ? '中文' : 'English';
  languageButton.setAttribute('aria-label',lang === 'en' ? '切换到简体中文' : 'Switch to English');
  document.title = lang === 'en' ? 'CodexBar — Your quota, at a glance.' : 'CodexBar — 剩余额度，一眼便知。';
  document.querySelector('meta[name="description"]').content = lang === 'en' ? 'A minimal, native macOS menu bar app for your Codex quota and reset times.' : '轻巧、原生的 macOS 菜单栏工具，随时查看 Codex 剩余额度与重置时间。';
  document.querySelector('.states').setAttribute('aria-label', lang === 'en' ? 'Preview remaining quota' : '预览剩余额度');
  document.querySelector('.demo').setAttribute('aria-label', lang === 'en' ? 'Interactive menu bar preview' : '交互菜单栏预览');
}
languageButton.addEventListener('click',() => { lang = lang === 'en' ? 'zh' : 'en'; renderLanguage(); try { localStorage.setItem('codexbar-language',lang); } catch {} });
document.querySelectorAll('[data-quota]').forEach(button => button.addEventListener('click',() => {
  const quota = Number(button.dataset.quota);
  document.getElementById('remaining').textContent = `${quota}%`;
  document.documentElement.style.setProperty('--quota',quota > 50 ? '#23844d' : quota >= 20 ? '#b87518' : '#c84b45');
  document.documentElement.style.setProperty('--angle',`${-90+quota*1.8}deg`);
  document.querySelectorAll('[data-quota]').forEach(item => item.setAttribute('aria-pressed',String(item === button)));
}));
renderLanguage();
