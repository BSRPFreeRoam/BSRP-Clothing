const app = document.getElementById('app');
const categoriesEl = document.getElementById('categories');
const contentEl = document.getElementById('content');
const sectionTitle = document.getElementById('sectionTitle');
const shopNameEl = document.getElementById('shopName');
const subtitleEl = document.getElementById('subtitle');

let state = null;
let activeCat = null;
let holdTimer = null;
let holdInterval = null;

function resourceName() {
    try {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
    } catch (e) {}
    return 'clothing';
}

function post(name, data) {
    return fetch('https://' + resourceName() + '/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {})
    }).then(function (r) {
        return r.json().catch(function () { return {}; });
    }).catch(function () {
        return {};
    });
}

function stopHold() {
    if (holdTimer) {
        clearTimeout(holdTimer);
        holdTimer = null;
    }
    if (holdInterval) {
        clearInterval(holdInterval);
        holdInterval = null;
    }
    document.querySelectorAll('.cam-btn.held').forEach(function (el) {
        el.classList.remove('held');
    });
}

function startHold(btn, fn) {
    stopHold();
    btn.classList.add('held');
    fn();
    holdTimer = setTimeout(function () {
        holdInterval = setInterval(fn, 70);
    }, 260);
}

function bindCam() {
    document.querySelectorAll('[data-cam]').forEach(function (btn) {
        const action = btn.getAttribute('data-cam');
        const fire = function () {
            post('camera', { action: action });
        };
        btn.addEventListener('mousedown', function (e) {
            e.preventDefault();
            startHold(btn, fire);
        });
        btn.addEventListener('mouseup', stopHold);
        btn.addEventListener('mouseleave', stopHold);
        btn.addEventListener('touchstart', function (e) {
            e.preventDefault();
            startHold(btn, fire);
        }, { passive: false });
        btn.addEventListener('touchend', stopHold);
    });

    document.querySelectorAll('[data-ped]').forEach(function (btn) {
        const dir = btn.getAttribute('data-ped');
        const fire = function () {
            post('rotatePed', { dir: dir });
        };
        btn.addEventListener('mousedown', function (e) {
            e.preventDefault();
            startHold(btn, fire);
        });
        btn.addEventListener('mouseup', stopHold);
        btn.addEventListener('mouseleave', stopHold);
        btn.addEventListener('touchstart', function (e) {
            e.preventDefault();
            startHold(btn, fire);
        }, { passive: false });
        btn.addEventListener('touchend', stopHold);
    });
}

function clampInt(val, min, max) {
    let n = parseInt(val, 10);
    if (isNaN(n)) n = min;
    if (n < min) n = min;
    if (n > max) n = max;
    return n;
}

function wrapIndex(val, min, max) {
    if (max < min) return min;
    let n = val;
    const span = max - min + 1;
    while (n < min) n += span;
    while (n > max) n -= span;
    return n;
}

function captureFieldFocus() {
    const el = document.activeElement;
    if (!el || !el.getAttribute) return null;
    const key = el.getAttribute('data-focus-key');
    if (!key) return null;
    return {
        key: key,
        start: typeof el.selectionStart === 'number' ? el.selectionStart : null,
        end: typeof el.selectionEnd === 'number' ? el.selectionEnd : null,
        value: el.value
    };
}

function restoreFieldFocus(info) {
    if (!info || !info.key) return;
    const el = contentEl.querySelector('[data-focus-key="' + info.key + '"]');
    if (!el) return;
    el.focus();
    if (info.start != null && typeof el.setSelectionRange === 'function') {
        try {
            el.setSelectionRange(info.start, info.end != null ? info.end : info.start);
        } catch (e) {}
    }
}

function renderCategories() {
    categoriesEl.innerHTML = '';
    if (!state || !state.categories) return;

    state.categories.forEach(function (cat) {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'cat-btn' + (activeCat && activeCat.key === cat.key ? ' active' : '');
        btn.innerHTML =
            '<span class="cat-icon">' + (cat.icon || '•') + '</span>' +
            '<span class="cat-label">' + cat.label + '</span>';
        btn.addEventListener('click', function () {
            activeCat = cat;
            renderCategories();
            renderContent();
        });
        categoriesEl.appendChild(btn);
    });
}

function applyPreview(kind, payload, opts) {
    opts = opts || {};
    const focus = captureFieldFocus();
    return post('preview', Object.assign({ kind: kind }, payload)).then(function (res) {
        if (res && res.ok && res.state && activeCat) {
            if (!state.slots) state.slots = {};
            state.slots[activeCat.key] = res.state;
            if (!opts.silent) {
                renderContent();
                restoreFieldFocus(focus);
            }
        }
        return res;
    });
}

/**
 * Full control row: label, +/-, range slider, number text input + GO
 * count = number of options (max index = count - 1)
 * onSet(absoluteValue, meta)
 */
function makeStepRow(label, value, count, onSet, focusKey) {
    const min = 0;
    const max = Math.max((count || 1) - 1, 0);
    let current = clampInt(value, min, max);
    const key = focusKey || (label + '').toLowerCase().replace(/\s+/g, '_');

    const wrap = document.createElement('div');
    wrap.className = 'step-block';

    const row = document.createElement('div');
    row.className = 'slot-row';
    const nameEl = document.createElement('span');
    nameEl.className = 'slot-name';
    nameEl.textContent = label;
    const numEl = document.createElement('span');
    numEl.className = 'slot-num';
    numEl.textContent = current + ' / ' + max;
    row.appendChild(nameEl);
    row.appendChild(numEl);
    wrap.appendChild(row);

    // +/- and slider
    const ctrl = document.createElement('div');
    ctrl.className = 'ctrl-row';

    const prev = document.createElement('button');
    prev.type = 'button';
    prev.className = 'step-btn';
    prev.textContent = '−';
    prev.title = 'Previous';

    const slider = document.createElement('input');
    slider.type = 'range';
    slider.className = 'value-slider';
    slider.min = String(min);
    slider.max = String(Math.max(max, 0));
    slider.step = '1';
    slider.value = String(current);
    if (count <= 0) {
        slider.disabled = true;
        slider.max = '0';
        slider.value = '0';
    }

    const next = document.createElement('button');
    next.type = 'button';
    next.className = 'step-btn';
    next.textContent = '+';
    next.title = 'Next';

    ctrl.appendChild(prev);
    ctrl.appendChild(slider);
    ctrl.appendChild(next);
    wrap.appendChild(ctrl);

    // text entry
    const textRow = document.createElement('div');
    textRow.className = 'text-row';

    const input = document.createElement('input');
    input.type = 'text';
    input.inputMode = 'numeric';
    input.pattern = '[0-9]*';
    input.className = 'value-input';
    input.setAttribute('data-focus-key', key);
    input.value = String(current);
    input.placeholder = '0';
    input.title = 'Type a number (' + min + '–' + max + ')';
    input.autocomplete = 'off';
    input.spellcheck = false;

    const goBtn = document.createElement('button');
    goBtn.type = 'button';
    goBtn.className = 'btn primary go-btn';
    goBtn.textContent = 'GO';
    goBtn.title = 'Apply number';

    const maxHint = document.createElement('span');
    maxHint.className = 'value-max-hint';
    maxHint.textContent = 'max ' + max;

    textRow.appendChild(input);
    textRow.appendChild(goBtn);
    textRow.appendChild(maxHint);
    wrap.appendChild(textRow);

    function syncUi(v) {
        current = clampInt(v, min, max);
        numEl.textContent = current + ' / ' + max;
        slider.value = String(current);
        if (document.activeElement !== input) {
            input.value = String(current);
        }
    }

    function commit(v, wrapAround, meta) {
        let nextVal;
        if (wrapAround) {
            nextVal = wrapIndex(v, min, max);
        } else {
            nextVal = clampInt(v, min, max);
        }
        syncUi(nextVal);
        onSet(nextVal, meta || {});
    }

    prev.addEventListener('click', function () {
        commit(current - 1, true);
    });
    next.addEventListener('click', function () {
        commit(current + 1, true);
    });

    // Drag: live preview without rebuild (keeps slider smooth)
    slider.addEventListener('input', function () {
        const v = clampInt(slider.value, min, max);
        current = v;
        numEl.textContent = v + ' / ' + max;
        if (document.activeElement !== input) {
            input.value = String(v);
        }
        onSet(v, { silent: true });
    });
    // Release: full refresh (updates texture max etc.)
    slider.addEventListener('change', function () {
        commit(slider.value, false);
    });

    function applyText() {
        commit(input.value, false);
        input.value = String(current);
    }

    goBtn.addEventListener('click', applyText);
    input.addEventListener('keydown', function (e) {
        e.stopPropagation();
        if (e.key === 'Enter') {
            e.preventDefault();
            applyText();
        }
    });
    input.addEventListener('blur', function () {
        // snap display if left incomplete
        const n = parseInt(input.value, 10);
        if (!isNaN(n)) {
            input.value = String(clampInt(n, min, max));
        } else {
            input.value = String(current);
        }
    });

    return wrap;
}

function renderComponentControls(cat, slot) {
    const maxD = slot.maxDrawable || 1;
    const maxT = slot.maxTexture || 1;
    const d = slot.drawable || 0;
    const t = slot.texture || 0;

    contentEl.innerHTML = '';
    const card = document.createElement('div');
    card.className = 'slot-card';

    card.appendChild(makeStepRow('STYLE', d, maxD, function (nd, meta) {
        applyPreview('component', {
            componentId: cat.componentId,
            drawable: nd,
            texture: 0
        }, meta);
    }, 'comp_style_' + cat.componentId));

    const texWrap = makeStepRow('TEXTURE', t, maxT, function (nt, meta) {
        applyPreview('component', {
            componentId: cat.componentId,
            drawable: d,
            texture: nt
        }, meta);
    }, 'comp_tex_' + cat.componentId);
    texWrap.style.marginTop = '14px';
    card.appendChild(texWrap);

    contentEl.appendChild(card);
}

function renderHairColorControls(cat, slot) {
    const max = slot.maxColor || 64;
    const primary = slot.primary || 0;
    const highlight = slot.highlight || 0;

    contentEl.innerHTML = '';
    const card = document.createElement('div');
    card.className = 'slot-card';

    card.appendChild(makeStepRow('PRIMARY', primary, max, function (np, meta) {
        applyPreview('hair_color', { primary: np, highlight: highlight }, meta);
    }, 'hair_primary'));

    const hiWrap = makeStepRow('HIGHLIGHT', highlight, max, function (nh, meta) {
        applyPreview('hair_color', { primary: primary, highlight: nh }, meta);
    }, 'hair_highlight');
    hiWrap.style.marginTop = '14px';
    card.appendChild(hiWrap);

    contentEl.appendChild(card);
}

function renderPropControls(cat, slot) {
    const maxD = slot.maxDrawable || 0;
    const maxT = slot.maxTexture || 1;
    let d = slot.drawable;
    if (d === undefined || d === null) d = -1;
    const t = slot.texture || 0;
    const has = d >= 0;

    contentEl.innerHTML = '';
    const card = document.createElement('div');
    card.className = 'slot-card';

    if (maxD > 0) {
        // When none, show style controls starting at 0 if they pick a value
        const styleVal = has ? d : 0;
        card.appendChild(makeStepRow('STYLE', styleVal, maxD, function (nd, meta) {
            applyPreview('prop', { propId: cat.propId, drawable: nd, texture: 0 }, meta);
        }, 'prop_style_' + cat.propId));
    } else {
        const empty = document.createElement('div');
        empty.className = 'empty-hint';
        empty.style.padding = '12px';
        empty.textContent = 'No styles available for this prop on this ped.';
        card.appendChild(empty);
    }

    if (has && maxD > 0) {
        const texWrap = makeStepRow('TEXTURE', t, maxT, function (nt, meta) {
            applyPreview('prop', { propId: cat.propId, drawable: d, texture: nt }, meta);
        }, 'prop_tex_' + cat.propId);
        texWrap.style.marginTop = '14px';
        card.appendChild(texWrap);
    }

    const noneBtn = document.createElement('button');
    noneBtn.type = 'button';
    noneBtn.className = 'none-btn';
    noneBtn.textContent = has ? 'REMOVE PROP' : 'NO PROP EQUIPPED';
    noneBtn.addEventListener('click', function () {
        applyPreview('prop', { propId: cat.propId, drawable: -1, texture: 0 });
    });
    card.appendChild(noneBtn);
    contentEl.appendChild(card);

    prevD.addEventListener('click', function () {
        if (maxD <= 0) return;
        let nd = has ? d - 1 : maxD - 1;
        if (nd < 0) nd = maxD - 1;
        applyPreview('prop', { propId: cat.propId, drawable: nd, texture: 0 });
    });
    nextD.addEventListener('click', function () {
        if (maxD <= 0) return;
        let nd = has ? d + 1 : 0;
        if (nd >= maxD) nd = 0;
        applyPreview('prop', { propId: cat.propId, drawable: nd, texture: 0 });
    });
}

function renderPeds() {
    contentEl.innerHTML = '';
    const peds = (state && state.peds) || [];
    const current = (state && state.currentPed) || '';

    if (!peds.length) {
        contentEl.innerHTML = '<div class="empty-hint">No ped models configured.</div>';
        return;
    }

    const search = document.createElement('input');
    search.type = 'text';
    search.className = 'ped-search';
    search.placeholder = 'Search ped…';
    search.maxLength = 40;
    contentEl.appendChild(search);

    const list = document.createElement('div');
    list.className = 'ped-list';
    contentEl.appendChild(list);

    function draw(filter) {
        list.innerHTML = '';
        const q = (filter || '').toLowerCase();
        let lastGroup = null;
        let shown = 0;

        peds.forEach(function (ped) {
            const label = ped.label || ped.model;
            const group = ped.group || 'Other';
            if (q) {
                const hay = (label + ' ' + ped.model + ' ' + group).toLowerCase();
                if (hay.indexOf(q) === -1) return;
            }

            if (group !== lastGroup) {
                lastGroup = group;
                const g = document.createElement('div');
                g.className = 'ped-group';
                g.textContent = group;
                list.appendChild(g);
            }

            const row = document.createElement('button');
            row.type = 'button';
            const isActive = ped.model === current;
            row.className = 'ped-item' + (isActive ? ' active' : '');
            row.innerHTML =
                '<span class="ped-label">' + label + '</span>' +
                '<span class="ped-model">' + ped.model + '</span>' +
                (isActive ? '<span class="ped-badge">ACTIVE</span>' : '');
            row.addEventListener('click', function () {
                if (isActive) return;
                post('setPed', { model: ped.model }).then(function (res) {
                    if (res && res.ok && res.data) {
                        state = res.data;
                        renderCategories();
                        renderContent();
                    }
                });
            });
            list.appendChild(row);
            shown += 1;
        });

        if (!shown) {
            list.innerHTML = '<div class="empty-hint">No peds match your search.</div>';
        }
    }

    search.addEventListener('input', function () {
        draw(search.value.trim());
    });
    search.addEventListener('keydown', function (e) {
        e.stopPropagation();
    });

    draw('');

    const hint = document.createElement('div');
    hint.className = 'outfit-empty';
    hint.style.marginTop = '10px';
    hint.textContent = 'Changing ped resets clothing to default for that model. Save an outfit after customizing.';
    contentEl.appendChild(hint);
}

function renderSaved() {
    contentEl.innerHTML = '';

    const saveBox = document.createElement('div');
    saveBox.className = 'save-box';
    const input = document.createElement('input');
    input.type = 'text';
    input.placeholder = 'Outfit name…';
    input.maxLength = 32;
    const saveBtn = document.createElement('button');
    saveBtn.type = 'button';
    saveBtn.className = 'btn primary';
    saveBtn.textContent = 'SAVE';
    saveBox.appendChild(input);
    saveBox.appendChild(saveBtn);
    contentEl.appendChild(saveBox);

    saveBtn.addEventListener('click', function () {
        post('saveOutfit', { name: input.value }).then(function (res) {
            if (res && res.ok && res.outfits) {
                state.outfits = res.outfits;
                input.value = '';
                renderSaved();
            }
        });
    });

    input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            saveBtn.click();
        }
        e.stopPropagation();
    });

    const list = document.createElement('div');
    list.className = 'outfit-list';
    const outfits = (state && state.outfits) || [];

    if (!outfits.length) {
        const empty = document.createElement('div');
        empty.className = 'outfit-empty';
        empty.textContent = 'No saved outfits yet. Style your look, then save it here. Stored locally (no SQL).';
        list.appendChild(empty);
    } else {
        outfits.forEach(function (o) {
            const row = document.createElement('div');
            row.className = 'outfit-item';
            const name = document.createElement('div');
            name.className = 'outfit-name';
            name.textContent = o.name || ('Outfit ' + o.id);
            const wear = document.createElement('button');
            wear.type = 'button';
            wear.className = 'btn primary';
            wear.textContent = 'LOAD';
            const del = document.createElement('button');
            del.type = 'button';
            del.className = 'btn danger';
            del.textContent = 'DEL';
            wear.addEventListener('click', function () {
                post('loadOutfit', { id: o.id }).then(function (res) {
                    if (res && res.ok && res.data) {
                        state = res.data;
                        renderCategories();
                        renderSaved();
                    }
                });
            });
            del.addEventListener('click', function () {
                post('deleteOutfit', { id: o.id }).then(function (res) {
                    if (res && res.ok && res.outfits) {
                        state.outfits = res.outfits;
                        renderSaved();
                    }
                });
            });
            row.appendChild(name);
            row.appendChild(wear);
            row.appendChild(del);
            list.appendChild(row);
        });
    }

    contentEl.appendChild(list);

    const hint = document.createElement('div');
    hint.className = 'outfit-empty';
    hint.style.marginTop = '8px';
    hint.textContent = 'Max ' + ((state && state.maxOutfits) || 12) + ' outfits · client KVP storage';
    contentEl.appendChild(hint);
}

function updateStripActiveUI() {
    const active = (state && state.stripActive) || {};
    document.querySelectorAll('[data-strip]').forEach(function (btn) {
        const key = btn.getAttribute('data-strip');
        if (active[key]) {
            btn.classList.add('active');
            btn.title = (btn.getAttribute('data-label') || key) + ' — click to put back on';
        } else {
            btn.classList.remove('active');
            btn.title = (btn.getAttribute('data-label') || key) + ' — click to take off';
        }
    });
}

function doStrip(key) {
    return post('strip', { key: key }).then(function (res) {
        if (res && res.ok && res.data) {
            state = res.data;
            updateStripActiveUI();
            renderCategories();
            renderContent();
        }
        return res;
    });
}

function doEmote(key) {
    return post('emote', { key: key });
}

function renderActionGrid(items, kind) {
    contentEl.innerHTML = '';
    const grid = document.createElement('div');
    grid.className = 'action-grid';

    (items || []).forEach(function (item) {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'action-card';
        btn.innerHTML =
            '<span class="a-icon">' + (item.icon || '•') + '</span>' +
            '<span class="a-label">' + (item.label || item.key) + '</span>';
        btn.addEventListener('click', function () {
            if (kind === 'emote') {
                doEmote(item.key);
            } else {
                doStrip(item.key);
            }
        });
        grid.appendChild(btn);
    });

    if (!items || !items.length) {
        contentEl.innerHTML = '<div class="empty-hint">No actions available.</div>';
        return;
    }

    contentEl.appendChild(grid);

    const hint = document.createElement('div');
    hint.className = 'outfit-empty';
    hint.style.marginTop = '12px';
    if (kind === 'emote') {
        hint.textContent = 'Hands up works in the store. Stop emote clears the animation.';
    } else {
        hint.textContent = 'Quick remove clothing pieces. Best results on freemode peds.';
    }
    contentEl.appendChild(hint);
}

function renderStripBar(show) {
    const bar = document.getElementById('stripBar');
    if (!bar) return;
    if (show) {
        bar.classList.remove('hidden');
    } else {
        bar.classList.add('hidden');
    }
}

function bindStripBar() {
    const bar = document.getElementById('stripBar');
    if (!bar || bar.dataset.bound === '1') return;
    bar.dataset.bound = '1';
    bar.querySelectorAll('[data-strip]').forEach(function (btn) {
        const key = btn.getAttribute('data-strip');
        const labels = {
            hat: 'Hat', mask: 'Mask', glasses: 'Glasses',
            shirt: 'Shirt', shoes: 'Shoes', pants: 'Pants'
        };
        btn.setAttribute('data-label', labels[key] || key);
        btn.addEventListener('click', function () {
            doStrip(key);
        });
    });
    bar.querySelectorAll('[data-emote]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            doEmote(btn.getAttribute('data-emote'));
        });
    });
}

function renderContent() {
    if (!activeCat) {
        sectionTitle.textContent = 'Select a category';
        const hint = (state && state.shopType === 'barber')
            ? 'Choose a barber option to cut, color, or save a style.'
            : 'Choose a clothing category, strip gear, or hands-up emote.';
        contentEl.innerHTML = '<div class="empty-hint">' + hint + '</div>';
        return;
    }

    sectionTitle.textContent = activeCat.label;

    if (activeCat.kind === 'saved') {
        renderSaved();
        return;
    }

    if (activeCat.kind === 'ped') {
        renderPeds();
        return;
    }

    if (activeCat.kind === 'emotes') {
        renderActionGrid((state && state.emotes) || [], 'emote');
        return;
    }

    if (activeCat.kind === 'strip') {
        renderActionGrid((state && state.stripActions) || [], 'strip');
        // mark active (removed) cards
        const active = (state && state.stripActive) || {};
        contentEl.querySelectorAll('.action-card').forEach(function (btn, idx) {
            const items = (state && state.stripActions) || [];
            const item = items[idx];
            if (item && active[item.key]) {
                btn.style.borderColor = 'rgba(255,45,85,0.65)';
                btn.style.boxShadow = '0 0 12px rgba(255,45,85,0.25)';
            }
        });
        return;
    }

    const slot = (state.slots && state.slots[activeCat.key]) || {
        drawable: 0,
        texture: 0,
        maxDrawable: 1,
        maxTexture: 1
    };

    if (activeCat.kind === 'component') {
        renderComponentControls(activeCat, slot);
    } else if (activeCat.kind === 'hair_color') {
        renderHairColorControls(activeCat, slot);
    } else if (activeCat.kind === 'prop') {
        renderPropControls(activeCat, slot);
    }
}

function openUi(data) {
    state = data || {};
    activeCat = null;
    shopNameEl.textContent = state.shopName || 'CLOTHING';
    subtitleEl.textContent = state.subtitle || 'WARDROBE';
    app.classList.remove('hidden');
    bindStripBar();
    renderStripBar(!!state.showStripBar);
    updateStripActiveUI();
    renderCategories();
    renderContent();
}

function closeUi(keep) {
    stopHold();
    app.classList.add('hidden');
    renderStripBar(false);
    state = null;
    activeCat = null;
    post('close', { keep: !!keep });
}

document.getElementById('btnWear').addEventListener('click', function () {
    closeUi(true);
});

document.getElementById('btnCancel').addEventListener('click', function () {
    closeUi(false);
});

document.getElementById('btnReset').addEventListener('click', function () {
    post('resetOriginal', {}).then(function (res) {
        if (res && res.ok && res.data) {
            state = res.data;
            if (activeCat && activeCat.kind !== 'saved') {
                // refresh slot values
            }
            renderCategories();
            renderContent();
        }
    });
});

window.addEventListener('message', function (event) {
    const msg = event.data || {};
    if (msg.action === 'open') {
        openUi(msg.data);
    } else if (msg.action === 'close') {
        stopHold();
        app.classList.add('hidden');
        renderStripBar(false);
        state = null;
        activeCat = null;
    }
});

bindStripBar();

document.addEventListener('keydown', function (e) {
    if (app.classList.contains('hidden')) return;
    if (e.key === 'Escape') {
        // Don't steal escape from outfit name field mid-type unless empty focus
        const tag = (document.activeElement && document.activeElement.tagName) || '';
        if (tag === 'INPUT' || tag === 'TEXTAREA') return;
        closeUi(false);
    }
});

bindCam();
