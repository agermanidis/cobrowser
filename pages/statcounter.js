if ("undefined" == typeof nRelateJS) {
    if ("undefined" == typeof nr_keywords) {
        var nr_keywords = "";
        if (document.getElementsByName) for (var metaArray = document.getElementsByName("keywords"), i = 0; i < metaArray.length; i++) nr_keywords += metaArray[i].content + " ";
        "" == nr_keywords && (nr_keywords = document.title)
    }
    if ("undefined" == typeof nr_pageurl) var nr_pageurl = window.location.href;
    if ("undefined" == typeof nr_sourcehp) var nr_sourcehp = !1;
    var nRelateJS = window.nRelateJS = {
        domain: nr_pageurl.match(/:\/\/(.[^/]+)/)[1],
        api_url: "http://api.nrelate.com/rcw_js/0.50.0/",
        clicked_link: null,
        load_link: !1,
        domready: !1,
        domready_bound: !1,
        domready_list: [],
        ie_browser: "Microsoft Internet Explorer" == navigator.appName,
        req_posts: [],
        loadFrame: function () {
            var b = nRelateJS;
            b.load_link && (b.load_link = !1, window.location.href = b.clicked_link)
        },
        innerText: function (b) {
            var a = document.getElementsByTagName("body");
            if (0 == a.length) return "";
            t = void 0 != a[0].innerText ? b.innerText : b.textContent;
            return "undefined" == typeof t ? "" : t = t.replace(/^[\s\t\n\r]*/, "")
                .replace(/[\s\t\n\r]*$/, "")
        },
        ie6fix: function (b) {
            for (var a = nRelateJS.xGetElementsByClassName(b), c = RegExp("(^|\\s)" + b + "(\\s|$)", "g"), b = 0; b < a.length; b++) a[b].className = a[b].className.replace(c, " ")
        },
        eventSource: function (b) {
            var a = null;
            b.target ? a = b.target : b.srcElement && (a = b.srcElement);
            3 == a.nodeType && (a = a.parentNode);
            return a
        },
        onclick: function (b) {
            var a = null,
                c = nRelateJS,
                d = !1;
            if (2 == b.which || b.ctrlKey || b.metaKey) d = !0;
            b || (b = window.event);
            for (a = c.eventSource(b);
            "A" != a.nodeName;) a = a.parentNode;
            var g = window.location.href,
                f = "http://t.nrelate.com/tracking/",
                h = document.createElement("iframe"),
                e = a.className,
                a = a.href;
            if (-1 != e.indexOf("nr_partner")) return !0;
            nr_type = -1 != e.indexOf("nr_external") ? "external" : "internal";
            f += "?plugin=rc&type=" + nr_type + "&domain=" + encodeURIComponent(c.domain) + "&src_url=" + encodeURIComponent(g) + "&dest_url=" + encodeURIComponent(a);
            c.load_link = d ? !1 : !0;
            c.clicked_link = a;
            h.setAttribute("id", "nr_clickthrough_frame_" + Math.ceil(100 * Math.random()));
            h.setAttribute("height", 0);
            h.setAttribute("width", 0);
            h.setAttribute("style", 'style="border-width: 0px; display:none;"');
            "undefined" != typeof h.addEventListener ? h.addEventListener("load", c.loadFrame, !1) : "undefined" != typeof h.attachEvent ? h.attachEvent("onload", c.loadFrame) : window.onLoad && (h.onload = c.loadFrame);
            h.src = f;
            document.getElementsByTagName("body")[0].appendChild(h);
            if (d) return !0;
            b.cancelBubble = !0;
            b.returnValue = !1;
            b.stopPropagation && (b.stopPropagation(), b.preventDefault());
            return !1
        },
        tracking: function (b) {
            for (var a = nRelateJS, c = [], c = a.xGetElementsByClassName("nr_link", b, "a"), b = 0; b < c.length; b++) c[b].onclick = a.onclick
        },
        fixHeight: function (b) {
            var a = nRelateJS,
                c = [],
                c = a.xGetElementsByClassName,
                c = c("nr_panel", b, "a");
            if (0 != c.length) {
                var d = 0,
                    g = 0,
                    f = [],
                    h, e = 0,
                    j = 0,
                    g = 0,
                    g = a.xPageY(c[0]);
                for (h = 0; h < c.length; h++) {
                    b = c[h];
                    e = a.xPageY(b);
                    if (g != e) {
                        for (currentDiv = 0; currentDiv < f.length; currentDiv++) a.xHeight(f[currentDiv], d);
                        f.length = 0;
                        g = e;
                        d = a.xHeight(b);
                        f.push(b)
                    } else f.push(b), d = d < a.xHeight(b) ? a.xHeight(b) : d;
                    for (currentDiv = 0; currentDiv < f.length; currentDiv++) a.xHeight(f[currentDiv], d)
                }
                e = a.xPageY(c[0]);
                for (h = 0; h < c.length && a.xPageY(c[h]) == e; h++) j++;
                var g = Math.ceil(c.length / j),
                    d = a = 1,
                    l, n, k, m;
                for (h = 0; h < c.length; h++) b = c[h], f = 0 == a % 2 ? " nr_even_row" : " nr_odd_row", e = 0 == d % 2 ? " nr_even_col" : " nr_odd_col", l = 1 == d ? " nr_first_col" : "", n = d == j && "" == l ? " nr_last_col" : "", k = 1 == a ? " nr_first_row" : "", m = a == g && "" == k ? " nr_last_row" : "", b.className += " nr_row_" + a + " nr_col_" + d + f + e + l + n + k + m, d++, d > j && (d = 1, a++)
            }
        },
        adAnimation: function (b) {
            var a = nRelateJS,
                b = a.xGetElementsByClassName("nr_sponsored", b, "span");
            if (0 != b.length) for (var c = a.xWidth(b[0].parentNode) - 18, d = a.xAddEventListener, g = new a.xAnimation, a = 0; a < b.length; a++) d(b[a], "mouseover", function (a) {
                a = nRelateJS.eventSource(a);
                g.css(a, "left", 0, 150, 1)
            }, !1), d(b[a], "mouseout", function (a) {
                a = nRelateJS.eventSource(a);
                g.css(a, "left", c, 150, 1)
            }, !1)
        },
        getScript: function (b, a) {
            var c = document.createElement("script");
            c.type = "text/javascript";
            c.src = b;
            a && (c.async = !0);
            document.getElementsByTagName("head")[0].appendChild(c)
        },
        bindDomReady: function (b) {
            var a = nRelateJS;
            if (a.domready) b();
            else if (a.domready_list.push(b), !a.domready_bound) if (a.domready_bound = !0, document.addEventListener) document.addEventListener("DOMContentLoaded",
            a.domReadyReached, !1), window.addEventListener("load", a.domReadyReached, !1);
            else if (document.attachEvent) {
                document.attachEvent("onreadystatechange", a.readyStateChange);
                window.attachEvent("onload", a.domReadyReached);
                b = !1;
                try {
                    b = null == window.frameElement
                } catch (c) {}
                document.documentElement.doScroll && b && a.scrollCheck()
            }
        },
        readyStateChange: function () {
            var b = document,
                a = arguments.callee;
            "complete" === b.readyState && (b.detachEvent("onreadystatechange", a), nRelateJS.domReadyReached())
        },
        scrollCheck: function () {
            var b = nRelateJS;
            if (!b.domready) try {
                document.documentElement.doScroll("left")
            } catch (a) {
                setTimeout(b.scrollCheck, 0);
                return
            }
            b.domReadyReached()
        },
        domReadyReached: function () {
            var b = nRelateJS;
            if (!b.domready) {
                b.domready = !0;
                document.addEventListener && document.removeEventListener("DOMContentLoaded", b.domReadyReached, !1);
                for (var a = 0; a < b.domready_list.length; a++) b.domready_list[a]();
                b.domready_list = []
            }
        },
        getRelatedPosts: function (b) {
            var a = nRelateJS;
            a.ie_browser ? a.getScript(b, !0) : a.jsIframe(b, "nRelateJS=window.parent.nRelateJS;")
        },
        sw: function (b, a) {
            if ("var" != b.substr(0, 3)) {
                var c = nRelateJS;
                if (document.getElementById(a)) document.getElementById(a)
                    .innerHTML = b, c.fixHeight(a), c.adAnimation(a), c.tracking(a);
                else {
                    var d = arguments.callee;
                    setTimeout(function () {
                        d(b, a)
                    }, 100)
                }
            }
        },
        jsIframe: function (b, a) {
          console.log("performing iframe", b, a);
            var c = document;
            nrDiv = c.createElement("div");
            nrDiv.style.display = "none";
            ifr = c.createElement("iframe");
            ifr.frameBorder = "0";
            ifr.allowTransparency = "true";
            nrDiv.appendChild(ifr);
            c.body.appendChild(nrDiv);
            domainSrc = "javascript:var d=document.open(); d.domain='" + c.domain + "';";
            try {
                ifr.contentWindow.document.open()
            } catch (d) {
                iframe.src = domainSrc + "void(0);"
            }
            a = "string" == typeof a ? a : "";
            b = b.replace(/\'/g, "\\'");
            iframe_html = '<body onload="d=document; ' + a + "d.getElementsByTagName('head')[0].appendChild(d.createElement('script')).src='" + b + "';\"></body>";
            try {
                var g = ifr.contentWindow.document;
                g.write(iframe_html);
                g.close()
            } catch (f) {
                ifr.src = domainSrc + 'd.write("' + iframe_html.replace(/"/g, '\\"') + '");d.close();'
            }
        },
        addHolder: function (b, a) {
            if (!document.getElementById("nrelate_related_" + a)) {
                var c = document.createElement("div");
                c.setAttribute("id", "nrelate_related_" + a);
                b.appendChild(c)
            }
        },
        postRequested: function (b) {
            for (var a = nRelateJS.req_posts, c = 0; c < a.length; c++) if (a[c] == b) return !0;
            return !1
        },
        parseHtml: function (b) {
            var a = nRelateJS,
                c = a.addHolder,
                d = level2 = [],
                g = document.getElementById("Blog1"),
                f, h, e;
            h = null;
            var j = a.xGetElementsByClassName,
                l = a.xGetElementsByTagName,
                n = b ? "&source=hp" : "",
                k = b ? null : document.getElementById("nrelate_related_placeholder"),
                m = b ? null : document.getElementById("nrelate_related_backup_placeholder"),
                d = j("post", g, "div");
            if (0 < d.length) for (e = 0; e < d.length; e++) if (0 < (level2 = j("jump-link", d[e], "div"))
                .length) c(k ? k : level2[0], e);
            else if (0 < (level2 = j("post-body", d[e], "div"))
                .length) c(k ? k : level2[0], e);
            else if (0 < (level2 = j("post-footer", d[e], "div"))
                .length) c(k ? k : level2[0].previousSibling, e);
            else if (0 < (level2 = j("postfooter", d[e], "div"))
                .length) c(k ? k : level2[0].previousSibling, e);
            else if (0 < (level2 = j("entrytitle", d[e], "div"))
                .length) c(k ? k : level2[0], e);
            else {
                if (0 < (level2 = j("commentpage", d[e], "div"))
                    .length) c(k ? k : level2[0].previousSibling, e)
            } else if (0 < (d = j("single", g, "div"))
                .length) for (e = 0; e < d.length; e++) {
                if (0 < (level2 = j("post-body", d[e], "div"))
                    .length) c(k ? k : level2[0], e)
            } else if (0 < (d = j("story", g, "div"))
                .length || 0 < (d = j("post", g, "div"))
                .length) for (e = 0; e < d.length; e++) {
                if (0 < (level2 = j("post-body", d[e], "div"))
                    .length) c(k ? k : level2[0], e)
            } else if (0 < (d = j("wrap", g, "div"))
                .length) for (e = 0; e < d.length; e++) {
                if (0 < (level2 = j("content", d[e], "div"))
                    .length) c(k ? k : level2[0], e)
            } else if (0 < (d = j("blogPost", g, "div"))
                .length) for (e = 0; e < d.length; e++) c(k ? k : d[e], e);
            else if (0 < (d = j("postarea", g, "div"))
                .length) for (e = 0; e < d.length; e++) {
                if (0 < (level2 = j("post-footer-line", d[e], "div"))
                    .length) c(k ? k : level2.previousSibling, e)
            } else if (0 < (d = j("entry", g, "div"))
                .length) for (e = 0; e < d.length; e++) c(k ? k : d[e], e);
            if (b) d = j("post-title", g), 0 === d.length && (d = j("entry-title", g)), 0 === d.length && (d = l("h3", g)), 0 === d.length && (d = l("h2", g)), 0 === d.length && (d = l("h1", g));
            else {
                var j = [{
                    funct: j,
                    args: ["post-title", g]
                }, {
                    funct: j,
                    args: ["entry-title", g]
                }, {
                    funct: l,
                    args: ["h3", g]
                }, {
                    funct: l,
                    args: ["h2", g]
                }, {
                    funct: l,
                    args: ["h1", g]
                }],
                    d = [],
                    o = 0;
                for (e = 0; e < j.length; e++) {
                    h = j[e].funct.apply(this, j[e].args);
                    o++;
                    for (g = 0; g < h.length; g++) if (0 <= document.title.search(a.innerText(h[g]))) {
                        d = [h[g]];
                        h = !0;
                        break
                    } else d.push(h[g]);
                    if (!0 === h) break
                }!0 !== h && (d = [document.title])
            }
            if (0 < d.length) for (e = 0; e < d.length; e++) {
                if (b) {
                    if (h = l("a", d[e]), 0 == h.length || "undefined" == typeof (f = h[0].getAttribute("href")) || a.postRequested(f)) continue
                } else f = nr_pageurl;
                a.req_posts.push(f);
                h = "string" == typeof d[e] ? d[e] : a.innerText(d[e]);
                document.getElementById("nrelate_related_" + e) || (k ? c(k, e) : m && c(m, e));
                document.getElementById("nrelate_related_" + e) && a.getRelatedPosts(a.api_url + "?domain=" + a.domain + "&keywords=" + encodeURIComponent(h) + "&url=" + encodeURIComponent(f) + "&nr_div_number=" + e + n)
            }!a.ie_browser && !a.domready && setTimeout(a.parseHtml, 100)
        },
        filterNodes: function (b, a) {
            if (0 == b.length) return [];
            for (var c = [], d = 0; d < b.length; d++) a(b[d]) && c.push(b[d]);
            return c
        },
        xAddEventListener: function (b, a, c, d) {
            if (b = nRelateJS.xGetElementById(b)) if (a = a.toLowerCase(),
            b.addEventListener) b.addEventListener(a, c, d || !1);
            else if (b.attachEvent) b.attachEvent("on" + a, c);
            else {
                var g = b["on" + a];
                b["on" + a] = "function" == typeof g ? function (a) {
                    g(a);
                    c(a)
                } : c
            }
        },
        xAnimation: function (b) {
            this.res = b || 10;
            this.axes = function (a) {
                var b;
                if (!this.a || this.a.length != a) {
                    this.a = [];
                    for (b = 0; b < a; ++b) this.a[b] = {
                        i: 0,
                        t: 0,
                        d: 0,
                        v: 0
                    }
                }
            };
            this.init = function (a, b, d, g, f, h, e) {
                this.e = nRelateJS.xGetElementById(a);
                this.t = b;
                this.or = d;
                this.ot = g;
                this.oe = f;
                this.at = h || 0;
                this.v = [function (a) {
                    return a
                }, function (a) {
                    return Math.abs(Math.sin(a))
                },

                function (a) {
                    return 1 - Math.abs(Math.cos(a))
                }, function (a) {
                    return (1 - Math.cos(a)) / 2
                }, function (a) {
                    return 1 - Math.exp(6 * -a)
                }][this.at];
                this.qc = 1 + (e || 0);
                this.fq = 1 / this.t;
                if (0 < this.at && 4 > this.at && (this.fq *= this.qc * Math.PI, 1 == this.at || 2 == this.at)) this.fq /= 2;
                for (a = 0; a < this.a.length; ++a) this.a[a].d = this.a[a].t - this.a[a].i
            };
            this.run = function (a) {
                var b, d, g, f = this;
                a || (f.t1 = (new Date)
                    .getTime());
                f.tmr || (f.tmr = setInterval(function () {
                    f.et = (new Date)
                        .getTime() - f.t1;
                    if (f.et < f.t) {
                        f.f = f.v(f.et * f.fq);
                        for (b = 0; b < f.a.length; ++b) f.a[b].v = f.a[b].d * f.f + f.a[b].i;
                        f.or(f)
                    } else {
                        clearInterval(f.tmr);
                        f.tmr = null;
                        d = f.qc % 2;
                        for (b = 0; b < f.a.length; ++b) f.a[b].v = d ? f.a[b].t : f.a[b].i;
                        f.ot(f);
                        g = false;
                        typeof f.oe == "function" ? g = f.oe(f) : typeof f.oe == "string" && (g = eval(f.oe));
                        g && f.resume(1)
                    }
                }, f.res))
            };
            this.pause = function () {
                clearInterval(this.tmr);
                this.tmr = null
            };
            this.resume = function (a) {
                "undefined" != typeof this.tmr && !this.tmr && (this.t1 = (new Date)
                    .getTime(), a || (this.t1 -= this.et), this.run(!a))
            };
            this.css = function (a, b, d, g, f, h, e) {
                function j(a) {
                    a.e.style[a.prop] = Math.round(a.a[0].v) + "px"
                }
                this.axes(1);
                this.a[0].i = nRelateJS.xGetComputedStyle(a, b, !0);
                this.a[0].t = d;
                this.prop = nRelateJS.xCamelize(b);
                this.init(a, g, j, j, e, f, h);
                this.run()
            }
        },
        xCamelize: function (b) {
            var a, c, d;
            c = b.split("-");
            d = c[0];
            for (b = 1; b < c.length; ++b) a = c[b].charAt(0), d += c[b].replace(a, a.toUpperCase());
            return d
        },
        xClientHeight: function () {
            var b = nRelateJS,
                a = 0,
                c = document,
                d = window;
            (!c.compatMode || "CSS1Compat" == c.compatMode) && c.documentElement && c.documentElement.clientHeight ? a = c.documentElement.clientHeight : c.body && c.body.clientHeight ? a = c.body.clientHeight : b.xDef(d.innerWidth, d.innerHeight, c.width) && (a = d.innerHeight, c.width > d.innerWidth && (a -= 16));
            return a
        },
        xClientWidth: function () {
            var b = nRelateJS,
                a = 0,
                c = document,
                d = window;
            (!c.compatMode || "CSS1Compat" == c.compatMode) && !d.opera && c.documentElement && c.documentElement.clientWidth ? a = c.documentElement.clientWidth : c.body && c.body.clientWidth ? a = c.body.clientWidth : b.xDef(d.innerWidth, d.innerHeight, c.height) && (a = d.innerWidth, c.height > d.innerHeight && (a -= 16));
            return a
        },
        xDef: function () {
            for (var b = 0; b < arguments.length; ++b) if ("undefined" == typeof arguments[b]) return !1;
            return !0
        },
        xGetComputedStyle: function (b, a, c) {
            var d = nRelateJS;
            if (!(b = d.xGetElementById(b))) return null;
            var g = "undefined",
                f = document.defaultView;
            if (f && f.getComputedStyle)(b = f.getComputedStyle(b, "")) && (g = b.getPropertyValue(a));
            else if (b.currentStyle) g = b.currentStyle[d.xCamelize(a)];
            else return null;
            return c ? parseInt(g) || 0 : g
        },
        xGetElementById: function (b) {
            "string" == typeof b && (b = document.getElementById ? document.getElementById(b) : document.all ? document.all[b] : null);
            return b
        },
        xGetElementsByTagName: function (b, a) {
            var c = nRelateJS,
                d = null,
                b = b || "*",
                a = c.xGetElementById(a) || document;
            if ("undefined" != typeof a.getElementsByTagName) {
                if (d = a.getElementsByTagName(b), "*" == b && (!d || !d.length)) d = a.all
            } else "*" == b ? d = a.all : a.all && a.all.tags && (d = a.all.tags(b));
            return d || []
        },
        xGetElementsByClassName: function (b, a, c, d) {
            for (var g = nRelateJS, f = [], b = RegExp("(^|\\s)" + b + "(\\s|$)"), a = g.xGetElementsByTagName(c, a), c = 0; c < a.length; ++c) b.test(a[c].className) && (f[f.length] = a[c], d && d(a[c]));
            return f
        },
        xHeight: function (b, a) {
            var c = nRelateJS,
                d, g = 0,
                f = 0,
                h = 0,
                e = 0;
            if (!(b = c.xGetElementById(b))) return 0;
            a = c.xNum(a) ? 0 > a ? 0 : Math.round(a) : -1;
            d = c.xDef(b.style);
            if (b == document || "html" == b.tagName.toLowerCase() || "body" == b.tagName.toLowerCase()) a = c.xClientHeight();
            else if (d && c.xDef(b.offsetHeight) && c.xStr(b.style.height)) {
                if (0 <= a) {
                    "CSS1Compat" == document.compatMode && (g = c.xGetComputedStyle(b, "padding-top", 1), null !== g ? (f = c.xGetComputedStyle(b, "padding-bottom", 1), h = c.xGetComputedStyle(b, "border-top-width",
                    1), e = c.xGetComputedStyle(b, "border-bottom-width", 1)) : c.xDef(b.offsetHeight, b.style.height) && (b.style.height = a + "px", g = b.offsetHeight - a));
                    a -= g + f + h + e;
                    if (isNaN(a) || 0 > a) return;
                    b.style.height = a + "px"
                }
                a = b.offsetHeight
            } else d && xDef(b.style.pixelHeight) && (0 <= a && (b.style.pixelHeight = a), a = b.style.pixelHeight);
            return a
        },
        xNum: function () {
            for (var b = 0; b < arguments.length; ++b) if (isNaN(arguments[b]) || "number" != typeof arguments[b]) return !1;
            return !0
        },
        xPageY: function (b) {
            for (var a = nRelateJS, c = 0, b = a.xGetElementById(b); b;) a.xDef(b.offsetTop) && (c += b.offsetTop), b = a.xDef(b.offsetParent) ? b.offsetParent : null;
            return c
        },
        xStr: function (b) {
            for (var a = 0; a < arguments.length; ++a) if ("string" != typeof arguments[a]) return !1;
            return !0
        },
        xWidth: function (b, a) {
            var c = nRelateJS,
                d, g = 0,
                f = 0,
                h = 0,
                e = 0;
            if (!(b = c.xGetElementById(b))) return 0;
            a = c.xNum(a) ? 0 > a ? 0 : Math.round(a) : -1;
            d = c.xDef(b.style);
            if (b == document || "html" == b.tagName.toLowerCase() || "body" == b.tagName.toLowerCase()) a = c.xClientWidth();
            else if (d && c.xDef(b.offsetWidth) && c.xStr(b.style.width)) {
                if (0 <= a) {
                    "CSS1Compat" == document.compatMode && (g = c.xGetComputedStyle(b, "padding-left", 1), null !== g ? (f = c.xGetComputedStyle(b, "padding-right", 1), h = c.xGetComputedStyle(b, "border-left-width", 1), e = c.xGetComputedStyle(b, "border-right-width", 1)) : c.xDef(b.offsetWidth, b.style.width) && (b.style.width = a + "px", g = b.offsetWidth - a));
                    a -= g + f + h + e;
                    if (isNaN(a) || 0 > a) return;
                    b.style.width = a + "px"
                }
                a = b.offsetWidth
            } else d && c.xDef(b.style.pixelWidth) && (0 <= a && (b.style.pixelWidth = a), a = b.style.pixelWidth);
            return a
        }
    }
}
(function () {
    var b = nRelateJS,
        a = b.bindDomReady,
        c = b.parseHtml;
    a(function () {
        c(nr_sourcehp)
    })
})();
