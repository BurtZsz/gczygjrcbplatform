// 选品追踪页：读取 data/products.json 并渲染，支持分类与判断标签双重筛选
(function () {
  const state = { cat: 'all', tag: 'all', items: [] };
  const listEl = document.getElementById('list');

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function render() {
    const rows = state.items.filter(function (it) {
      const okCat = state.cat === 'all' || it.cat === state.cat;
      const okTag = state.tag === 'all' || (it.tags || []).indexOf(state.tag) !== -1;
      return okCat && okTag;
    });

    if (!rows.length) {
      listEl.innerHTML = '<p class="note">当前筛选下没有条目。换一个分类或判断条件试试。</p>';
      return;
    }

    listEl.innerHTML = rows.map(function (it) {
      const tags = (it.tags || []).map(function (t) {
        const cls = t === '课程' ? 'tag edu' : (t === '众筹' ? 'tag hot' : 'tag');
        const text = { '电商': '适合电商卖', '自用': '值得自己用', '课程': '可进 AI 课程', '众筹': '适合众筹' }[t] || t;
        return '<span class="' + cls + '">' + esc(text) + '</span>';
      }).join('');

      return '<article class="item">' +
        '<div class="item-head">' +
          '<h3>' + esc(it.name) + '</h3>' +
          '<span class="tag">' + esc(it.catLabel || '') + '</span>' +
          '<span class="price">' + esc(it.price) + '</span>' +
        '</div>' +
        '<p>' + esc(it.desc) + '</p>' +
        '<p><strong>判断：</strong>' + esc(it.verdict) + '</p>' +
        '<div class="meta">' +
          tags +
          '<span style="display:block;margin-top:8px">' +
            esc(it.date) +
            ' · 来源：<a href="' + esc(it.source.url) + '" target="_blank" rel="noopener">' + esc(it.source.label) + '</a>' +
          '</span>' +
        '</div>' +
      '</article>';
    }).join('');
  }

  function bindGroup(el, key) {
    el.addEventListener('click', function (e) {
      const btn = e.target.closest('.chip');
      if (!btn) return;
      el.querySelectorAll('.chip').forEach(function (c) { c.classList.remove('on'); });
      btn.classList.add('on');
      state[key] = btn.dataset[key];
      render();
    });
  }

  fetch('/product-tracking/data/products.json', { cache: 'no-store' })
    .then(function (r) { return r.json(); })
    .then(function (data) {
      state.items = data.items || [];
      const u = document.getElementById('updated');
      const c = document.getElementById('count');
      if (u) u.textContent = data.updated || '—';
      if (c) c.textContent = state.items.length;
      render();
    })
    .catch(function () {
      listEl.innerHTML = '<p class="note">数据读取失败。请确认 products.json 与本页在同一站点的 /product-tracking/data/ 路径下。</p>';
    });

  bindGroup(document.getElementById('filters'), 'cat');
  bindGroup(document.getElementById('tagfilters'), 'tag');
})();
