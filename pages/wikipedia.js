console.log("running");

function isCompatible() {
    if (navigator.appVersion.indexOf('MSIE') !== -1 && parseFloat(navigator.appVersion.split('MSIE')[1]) < 6) {
        return false;
    }
    return true;
}

console.log("running", 2);

var startUp = function () {
    mw.config = new mw.Map(true);
    mw.loader.addSource({
        "local": {
            "loadScript": "//bits.wikimedia.org/en.wikipedia.org/load.php",
            "apiScript": "/w/api.php"
        }
    });
    (function (name, version, dependencies, group, source) {})("MediaWikiSupport.loader", "20130102T193818Z", [], null, "local");
    (function (name, version, dependencies, group, source) {
        (function (mw, $) {
            $(function (event) {
                var $selected = $(mw.config.get('EmbedPlayer.RewriteSelector'));
                if ($selected.length) {
                    var inx = 0;
                    var checkSetDone = function () {
                        if (inx < $selected.length) {
                            $selected.slice(inx, inx + 1).embedPlayer(function () {
                                setTimeout(function () {
                                    checkSetDone();
                                }, 5);
                            });
                        }
                        inx++;
                    };
                    checkSetDone();
                }
            });
            $.fn.embedPlayer = function (readyCallback) {
                var playerSet = this;
                mw.log('jQuery.fn.embedPlayer :: ' + $(this).length);
                var dependencySet = ['mw.EmbedPlayer'];
                var rewriteElementCount = 0;
                $(this).each(function (inx,
                playerElement) {
                    var skinName = '';
                    $(playerElement).removeAttr('controls');
                    if (!$.browser.mozilla) {
                        $(playerElement).parent().getAbsoluteOverlaySpinner().attr('id', 'loadingSpinner_' + $(playerElement).attr('id'));
                    }
                    $(mw).trigger('EmbedPlayerUpdateDependencies', [playerElement, dependencySet]);
                });
                dependencySet = $.uniqueArray(dependencySet);
                mediaWiki.loader.using(dependencySet, function () {
                    window.gM = mw.jqueryMsg.getMessageFunction({});
                    mw.processEmbedPlayers(playerSet, readyCallback);
                }, function (e) {
                    throw new Error('Error loading EmbedPlayer dependency set: ' + e.message);
                });
            };
        })(window.mediaWiki, window.jQuery);
    })("EmbedPlayer.loader", "20130102T193917Z", [], null, "local");
    (function (name, version, dependencies, group, source) {
        (function (mw, $) {
            $(mw).bind('EmbedPlayerUpdateDependencies', function (event, playerElement, classRequest) {
                if (mw.isTimedTextSupported(playerElement)) {
                    classRequest = $.merge(classRequest, ['mw.TimedText']);
                }
            });
            $(mw).bind('EmbedPlayerNewPlayer', function (event, embedPlayer) {
                if (mw.isTimedTextSupported(
                embedPlayer)) {
                    embedPlayer.timedText = new mw.TimedText(embedPlayer);
                }
            });
            mw.isTimedTextSupported = function (embedPlayer) {
                var mwprovider = embedPlayer['data-mwprovider'] || $(embedPlayer).data('mwprovider');
                var showInterface = mw.config.get('TimedText.ShowInterface.' + mwprovider) || mw.config.get('TimedText.ShowInterface');
                if (showInterface == 'always') {
                    return true;
                } else if (showInterface == 'off') {
                    return false;
                }
                if ($(embedPlayer).find('track').length != 0) {
                    return true;
                } else {
                    return false;
                }
            };
        })(window.mediaWiki, window.jQuery);
    })("TimedText.loader", "20130102T193917Z", [], null, "local");
    (function (name, version, dependencies, group, source) {
        (function (mw, $) {
            $(mw).bind('EmbedPlayerUpdateDependencies', function (event, embedPlayer, dependencySet) {
                if ($(embedPlayer).attr('data-mwtitle')) {
                    $.merge(dependencySet, ['mw.MediaWikiPlayerSupport']);
                }
            });
        })(window.mediaWiki, jQuery);
    })("mw.MediaWikiPlayer.loader", "20130102T193917Z", [], null, "local");
    mw.loader.register([
        ["site", "1358197691", [], "site"],
        ["noscript", "1347062400", [], "noscript"],
        ["startup", "1358276351", [], "startup"],
        ["filepage", "1347062400"],
        ["user.groups", "1347062400", [], "user"],
        ["user", "1347062400", [], "user"],
        ["user.cssprefs", "1347062400", ["mediawiki.user"], "private"],
        ["user.options", "1347062400", [], "private"],
        ["user.tokens", "1347062400", [], "private"],
        ["mediawiki.language.data", "1358276351", ["mediawiki.language.init"]],
        ["skins.chick", "1357143067"],
        ["skins.cologneblue", "1357143067"],
        ["skins.modern", "1357143067"],
        ["skins.monobook", "1357143067"],
        ["skins.nostalgia", "1357143067"],
        ["skins.simple", "1357143067"],
        ["skins.standard", "1357143067"],
        ["skins.vector", "1357143067"],
        ["jquery", "1357143067"],
        ["jquery.appear", "1357143067"],
        ["jquery.arrowSteps", "1357143067"],
        ["jquery.async", "1357143067"],
        ["jquery.autoEllipsis", "1357143067", ["jquery.highlightText"]],
        ["jquery.badge", "1357143067"],
        ["jquery.byteLength", "1357143067"],
        ["jquery.byteLimit", "1357143067", ["jquery.byteLength"]],
        ["jquery.checkboxShiftClick", "1357143067"],
        ["jquery.client", "1357143067"],
        [
            "jquery.collapsibleTabs", "1357143067", ["jquery.delayedBind"]],
        ["jquery.color", "1357143067", ["jquery.colorUtil"]],
        ["jquery.colorUtil", "1357143067"],
        ["jquery.cookie", "1357143067"],
        ["jquery.delayedBind", "1357143067"],
        ["jquery.expandableField", "1357143067", ["jquery.delayedBind"]],
        ["jquery.farbtastic", "1357143067", ["jquery.colorUtil"]],
        ["jquery.footHovzer", "1357143067"],
        ["jquery.form", "1357143067"],
        ["jquery.getAttrs", "1357143067"],
        ["jquery.hidpi", "1357143067"],
        ["jquery.highlightText", "1357143067", ["jquery.mwExtension"]],
        ["jquery.hoverIntent", "1357143067"],
        ["jquery.json", "1357143067"],
        ["jquery.localize", "1357143067"],
        ["jquery.makeCollapsible", "1358216792"],
        ["jquery.mockjax", "1357143067"],
        ["jquery.mw-jump", "1357143067"],
        ["jquery.mwExtension", "1357143067"],
        ["jquery.placeholder", "1357143067"],
        ["jquery.qunit", "1357143067"],
        ["jquery.qunit.completenessTest", "1357143067", ["jquery.qunit"]],
        ["jquery.spinner", "1357143067"],
        ["jquery.jStorage", "1357143067", ["jquery.json"]],
        ["jquery.suggestions",
            "1357143067", ["jquery.autoEllipsis"]],
        ["jquery.tabIndex", "1357143067"],
        ["jquery.tablesorter", "1358216811", ["jquery.mwExtension"]],
        ["jquery.textSelection", "1357143067", ["jquery.client"]],
        ["jquery.validate", "1357143067"],
        ["jquery.xmldom", "1357143067"],
        ["jquery.tipsy", "1357143067"],
        ["jquery.ui.core", "1357143067", ["jquery"], "jquery.ui"],
        ["jquery.ui.widget", "1357143067", [], "jquery.ui"],
        ["jquery.ui.mouse", "1357143067", ["jquery.ui.widget"], "jquery.ui"],
        ["jquery.ui.position", "1357143067", [], "jquery.ui"],
        ["jquery.ui.draggable", "1357143067", ["jquery.ui.core", "jquery.ui.mouse", "jquery.ui.widget"], "jquery.ui"],
        ["jquery.ui.droppable", "1357143067", ["jquery.ui.core", "jquery.ui.mouse", "jquery.ui.widget", "jquery.ui.draggable"], "jquery.ui"],
        ["jquery.ui.resizable", "1357143067", ["jquery.ui.core", "jquery.ui.widget", "jquery.ui.mouse"], "jquery.ui"],
        ["jquery.ui.selectable", "1357143067", ["jquery.ui.core", "jquery.ui.widget", "jquery.ui.mouse"], "jquery.ui"],
        ["jquery.ui.sortable", "1357143067", ["jquery.ui.core",
            "jquery.ui.widget", "jquery.ui.mouse"], "jquery.ui"],
        ["jquery.ui.accordion", "1357143067", ["jquery.ui.core", "jquery.ui.widget"], "jquery.ui"],
        ["jquery.ui.autocomplete", "1357143067", ["jquery.ui.core", "jquery.ui.widget", "jquery.ui.position"], "jquery.ui"],
        ["jquery.ui.button", "1357143067", ["jquery.ui.core", "jquery.ui.widget"], "jquery.ui"],
        ["jquery.ui.datepicker", "1357143067", ["jquery.ui.core"], "jquery.ui"],
        ["jquery.ui.dialog", "1357143067", ["jquery.ui.core", "jquery.ui.widget", "jquery.ui.button", "jquery.ui.draggable", "jquery.ui.mouse", "jquery.ui.position", "jquery.ui.resizable"], "jquery.ui"],
        ["jquery.ui.progressbar", "1357143067", ["jquery.ui.core", "jquery.ui.widget"], "jquery.ui"],
        ["jquery.ui.slider", "1357143067", ["jquery.ui.core", "jquery.ui.widget", "jquery.ui.mouse"], "jquery.ui"],
        ["jquery.ui.tabs", "1357143067", ["jquery.ui.core", "jquery.ui.widget"], "jquery.ui"],
        ["jquery.effects.core", "1357143067", ["jquery"], "jquery.ui"],
        ["jquery.effects.blind", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        [
            "jquery.effects.bounce", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.clip", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.drop", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.explode", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.fade", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.fold", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.highlight", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.pulsate", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.scale", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.shake", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.slide", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["jquery.effects.transfer", "1357143067", ["jquery.effects.core"], "jquery.ui"],
        ["mediawiki", "1357143067"],
        ["mediawiki.api", "1357143067", ["mediawiki.util"]],
        ["mediawiki.api.category",
            "1357143067", ["mediawiki.api", "mediawiki.Title"]],
        ["mediawiki.api.edit", "1357143067", ["mediawiki.api", "mediawiki.Title"]],
        ["mediawiki.api.parse", "1357143067", ["mediawiki.api"]],
        ["mediawiki.api.titleblacklist", "1357143067", ["mediawiki.api", "mediawiki.Title"]],
        ["mediawiki.api.watch", "1357143067", ["mediawiki.api", "user.tokens"]],
        ["mediawiki.debug", "1357143067", ["jquery.footHovzer"]],
        ["mediawiki.debug.init", "1357143067", ["mediawiki.debug"]],
        ["mediawiki.feedback", "1358216858", ["mediawiki.api.edit", "mediawiki.Title", "mediawiki.jqueryMsg", "jquery.ui.dialog"]],
        ["mediawiki.hidpi", "1357143067", ["jquery.hidpi"]],
        ["mediawiki.htmlform", "1357143067"],
        ["mediawiki.notification", "1357143067", ["mediawiki.page.startup"]],
        ["mediawiki.notify", "1357143067"],
        ["mediawiki.searchSuggest", "1358216792", ["jquery.autoEllipsis", "jquery.client", "jquery.placeholder", "jquery.suggestions"]],
        ["mediawiki.Title", "1357143067", ["mediawiki.util"]],
        ["mediawiki.Uri", "1357143067"],
        ["mediawiki.user", "1357143067", ["jquery.cookie",
            "mediawiki.api", "user.options", "user.tokens"]],
        ["mediawiki.util", "1358216791", ["jquery.client", "jquery.cookie", "jquery.mwExtension", "mediawiki.notify"]],
        ["mediawiki.action.edit", "1357143067", ["jquery.textSelection", "jquery.byteLimit"]],
        ["mediawiki.action.edit.preview", "1357143067", ["jquery.form", "jquery.spinner"]],
        ["mediawiki.action.history", "1357143067", [], "mediawiki.action.history"],
        ["mediawiki.action.history.diff", "1357143067", [], "mediawiki.action.history"],
        ["mediawiki.action.view.dblClickEdit", "1357143067", ["mediawiki.util", "mediawiki.page.startup"]],
        ["mediawiki.action.view.metadata", "1358216802"],
        ["mediawiki.action.view.rightClickEdit", "1357143067"],
        ["mediawiki.action.watch.ajax", "1347062400", ["mediawiki.page.watch.ajax"]],
        ["mediawiki.language", "1357143067", ["mediawiki.language.data", "mediawiki.cldr"]],
        ["mediawiki.cldr", "1357143067", ["mediawiki.libs.pluralruleparser"]],
        ["mediawiki.libs.pluralruleparser", "1357143067"],
        ["mediawiki.language.init", "1357143067"],
        ["mediawiki.jqueryMsg",
            "1357143067", ["mediawiki.util", "mediawiki.language"]],
        ["mediawiki.libs.jpegmeta", "1357143067"],
        ["mediawiki.page.ready", "1357143067", ["jquery.checkboxShiftClick", "jquery.makeCollapsible", "jquery.placeholder", "jquery.mw-jump", "mediawiki.util"]],
        ["mediawiki.page.startup", "1357143067", ["jquery.client", "mediawiki.util"]],
        ["mediawiki.page.patrol.ajax", "1358217074", ["mediawiki.page.startup", "mediawiki.api", "mediawiki.util", "mediawiki.Title", "mediawiki.notify", "jquery.spinner", "user.tokens"]],
        ["mediawiki.page.watch.ajax", "1358216792", ["mediawiki.page.startup", "mediawiki.api.watch", "mediawiki.util", "mediawiki.notify", "jquery.mwExtension"]],
        ["mediawiki.special", "1357143067"],
        ["mediawiki.special.block", "1357143067", ["mediawiki.util"]],
        ["mediawiki.special.changeemail", "1358217666", ["mediawiki.util"]],
        ["mediawiki.special.changeslist", "1357143067", ["jquery.makeCollapsible"]],
        ["mediawiki.special.movePage", "1357143067", ["jquery.byteLimit"]],
        ["mediawiki.special.preferences", "1357143067"],
        [
            "mediawiki.special.recentchanges", "1357143067", ["mediawiki.special"]],
        ["mediawiki.special.search", "1358216801"],
        ["mediawiki.special.undelete", "1357143067"],
        ["mediawiki.special.upload", "1358216830", ["mediawiki.libs.jpegmeta", "mediawiki.util"]],
        ["mediawiki.special.javaScriptTest", "1357143067", ["jquery.qunit"]],
        ["mediawiki.tests.qunit.testrunner", "1357143067", ["jquery.qunit", "jquery.qunit.completenessTest", "mediawiki.page.startup", "mediawiki.page.ready"]],
        ["mediawiki.legacy.ajax", "1357143067", ["mediawiki.util", "mediawiki.legacy.wikibits"]],
        ["mediawiki.legacy.commonPrint", "1357143067"],
        ["mediawiki.legacy.config", "1357143067", ["mediawiki.legacy.wikibits"]],
        ["mediawiki.legacy.IEFixes", "1357143067", ["mediawiki.legacy.wikibits"]],
        ["mediawiki.legacy.protect", "1357143067", ["mediawiki.legacy.wikibits", "jquery.byteLimit"]],
        ["mediawiki.legacy.shared", "1357143067"],
        ["mediawiki.legacy.oldshared", "1357143067"],
        ["mediawiki.legacy.upload", "1357143067", ["mediawiki.legacy.wikibits", "mediawiki.util"]],
        [
            "mediawiki.legacy.wikibits", "1357143067", ["mediawiki.util"]],
        ["mediawiki.legacy.wikiprintable", "1357143067"],
        ["ext.gadget.WatchlistChangesBold", "1347062400"],
        ["ext.gadget.Navigation_popups", "1347062400"],
        ["ext.gadget.exlinks", "1347062400", ["mediawiki.util"]],
        ["ext.gadget.search-new-tab", "1351532178"],
        ["ext.gadget.Twinkle", "1357385791", ["mediawiki.util", "jquery.ui.dialog", "jquery.tipsy"]],
        ["ext.gadget.HideFundraisingNotice", "1347062400"],
        ["ext.gadget.teahouse", "1352405287", ["mediawiki.api", "jquery.ui.button"]],
        ["ext.gadget.ReferenceTooltips", "1347062400"],
        ["ext.gadget.DotsSyntaxHighlighter", "1354763577"],
        ["ext.gadget.HotCat", "1347062400"],
        ["ext.gadget.ProveIt", "1357110965", ["jquery.ui.tabs", "jquery.ui.button", "jquery.effects.highlight", "jquery.textSelection"]],
        ["ext.gadget.DRN-wizard", "1347062400"],
        ["ext.gadget.charinsert", "1349102026"],
        ["ext.gadget.UTCLiveClock", "1347062400"],
        ["ext.gadget.mySandbox", "1353351560", ["mediawiki.util", "mediawiki.Title", "mediawiki.Uri"]],
        [
            "ext.gadget.purgetab", "1349291568", ["mediawiki.util"]],
        ["ext.gadget.dropdown-menus", "1347062400"],
        ["ext.gadget.OldDiff", "1347062400"],
        ["ext.gadget.NoAnimations", "1347062400"],
        ["ext.gadget.NoSmallFonts", "1347062400"],
        ["ext.gadget.MenuTabsToggle", "1354977868", ["jquery.cookie"]],
        ["ext.gadget.Blackskin", "1347062400"],
        ["ext.gadget.widensearch", "1347062400"],
        ["ext.gadget.DejaVu_Sans", "1347062400"],
        ["ext.gadget.ShowMessageNames", "1347062400", ["mediawiki.util"]],
        ["ext.gadget.BugStatusUpdate", "1347062400"],
        ["ext.gadget.RTRC", "1347062400"],
        ["ext.gadget.textareasansserif", "1348943697", ["mediawiki.api"]],
        ["mw.MwEmbedSupport", "1357155498", ["jquery.triggerQueueCallback", "Spinner", "jquery.loadingSpinner", "jquery.mwEmbedUtil", "mw.MwEmbedSupport.style"]],
        ["Spinner", "1357155498"],
        ["iScroll", "1357155498"],
        ["jquery.loadingSpinner", "1357155498"],
        ["mw.MwEmbedSupport.style", "1357155498"],
        ["mediawiki.UtilitiesTime", "1357155498"],
        ["mediawiki.client", "1357155498"],
        ["mediawiki.absoluteUrl", "1357155498"],
        [
            "mw.ajaxProxy", "1357155498"],
        ["fullScreenApi", "1357155498"],
        ["jquery.embedMenu", "1357155498"],
        ["jquery.ui.touchPunch", "1357155498", ["jquery.ui.core", "jquery.ui.mouse"]],
        ["jquery.triggerQueueCallback", "1357155498"],
        ["jquery.mwEmbedUtil", "1357155498", ["jquery.ui.dialog"]],
        ["jquery.debouncedresize", "1357155498"],
        ["mw.Language.names", "1357155498"],
        ["mw.Api", "1357155498"],
        ["mw.MediaElement", "1357155557"],
        ["mw.MediaPlayer", "1357155557"],
        ["mw.MediaPlayers", "1357155557", ["mw.MediaPlayer"]],
        ["mw.MediaSource", "1357155557"],
        ["mw.EmbedTypes", "1357155557", ["mw.MediaPlayers", "mediawiki.Uri"]],
        ["mw.EmbedPlayer", "1358216803", ["mediawiki.client", "mediawiki.UtilitiesTime", "mediawiki.Uri", "mediawiki.absoluteUrl", "mediawiki.jqueryMsg", "fullScreenApi", "mw.EmbedPlayerNative", "mw.MediaElement", "mw.MediaPlayers", "mw.MediaSource", "mw.EmbedTypes", "jquery.client", "jquery.hoverIntent", "jquery.cookie", "jquery.ui.mouse", "jquery.debouncedresize", "jquery.embedMenu", "jquery.ui.slider", "jquery.ui.touchPunch",
            "mw.PlayerSkinKskin"]],
        ["mw.EmbedPlayerKplayer", "1357155557"],
        ["mw.EmbedPlayerGeneric", "1357155557"],
        ["mw.EmbedPlayerJava", "1357155557"],
        ["mw.EmbedPlayerNative", "1357155557"],
        ["mw.EmbedPlayerImageOverlay", "1357155557"],
        ["mw.EmbedPlayerVlc", "1357155557"],
        ["mw.PlayerSkinKskin", "1357155557"],
        ["mw.PlayerSkinMvpcf", "1357155557"],
        ["mw.TimedText", "1358216803", ["mw.EmbedPlayer", "jquery.ui.dialog", "mw.TextSource"]],
        ["mw.TextSource", "1357155557", ["mediawiki.UtilitiesTime", "mw.ajaxProxy"]],
        ["ext.articleFeedback.startup", "1357155351", ["mediawiki.util", "mediawiki.user"]],
        ["ext.articleFeedback", "1358216800", ["jquery.ui.dialog", "jquery.ui.button", "jquery.articleFeedback", "jquery.cookie", "jquery.clickTracking", "ext.articleFeedback.ratingi18n"]],
        ["ext.articleFeedback.ratingi18n", "1347062400"],
        ["ext.articleFeedback.dashboard", "1357155351"],
        ["jquery.articleFeedback", "1358216800", ["jquery.appear", "jquery.tipsy", "jquery.json", "jquery.localize", "jquery.ui.dialog", "jquery.ui.button", "jquery.cookie",
            "jquery.clickTracking", "mediawiki.jqueryMsg", "mediawiki.language"]],
        ["jquery.articleFeedbackv5.verify", "1357155360", ["mediawiki.util", "mediawiki.user"]],
        ["ext.articleFeedbackv5.startup", "1357155359", ["mediawiki.util", "mediawiki.user", "jquery.articleFeedbackv5.verify"]],
        ["ext.articleFeedbackv5", "1358216796", ["jquery.ui.button", "jquery.articleFeedbackv5", "jquery.cookie", "jquery.articleFeedbackv5.track"]],
        ["ext.articleFeedbackv5.ie", "1357155359"],
        ["ext.articleFeedbackv5.dashboard", "1358216874", ["jquery.articleFeedbackv5.verify", "jquery.articleFeedbackv5.special"]],
        ["jquery.articleFeedbackv5.track", "1357155360", ["mediawiki.util", "mediawiki.user", "jquery.clickTracking"]],
        ["ext.articleFeedbackv5.talk", "1358216804", ["jquery.articleFeedbackv5.verify", "jquery.articleFeedbackv5.track"]],
        ["ext.articleFeedbackv5.watchlist", "1358216800", ["jquery.articleFeedbackv5.track"]],
        ["jquery.articleFeedbackv5", "1358216796", ["jquery.appear", "jquery.tipsy", "jquery.json", "jquery.localize", "jquery.ui.button",
            "jquery.cookie", "jquery.placeholder", "mediawiki.jqueryMsg", "jquery.articleFeedbackv5.track", "jquery.effects.highlight", "mediawiki.Uri"]],
        ["jquery.articleFeedbackv5.special", "1358216874", ["mediawiki.util", "jquery.tipsy", "jquery.localize", "jquery.articleFeedbackv5.track", "jquery.json", "jquery.ui.button"]],
        ["mobile.device.default", "1357690202"],
        ["mobile.device.webkit", "1357690202"],
        ["mobile.device.ie", "1357690202"],
        ["mobile.device.android", "1357690202"],
        ["mobile.device.iphone", "1357690202"],
        ["mobile.device.iphone2", "1357690202"],
        ["mobile.device.palm_pre", "1357690202"],
        ["mobile.device.kindle", "1357690202"],
        ["mobile.device.blackberry", "1357690202"],
        ["mobile.device.simple", "1357690202"],
        ["mobile.device.psp", "1357690202"],
        ["mobile.device.wii", "1357690202"],
        ["mobile.device.operamini", "1357690202"],
        ["mobile.device.operamobile", "1357690202"],
        ["mobile.device.nokia", "1357690202"],
        ["schema.MobileBetaWatchlist", "1347062400", ["ext.eventLogging"]],
        ["ext.wikihiero", "1357155720"],
        [
            "ext.wikihiero.Special", "1358229556", ["jquery.spinner"]],
        ["ext.cite", "1357155388", ["jquery.tooltip"]],
        ["jquery.tooltip", "1357155388"],
        ["ext.specialcite", "1357155388"],
        ["ext.geshi.local", "1347062400"],
        ["ext.flaggedRevs.basic", "1357155451"],
        ["ext.flaggedRevs.advanced", "1358216824", ["mediawiki.util"]],
        ["ext.flaggedRevs.review", "1358216891", ["mediawiki.util", "mediawiki.user", "mediawiki.jqueryMsg"]],
        ["ext.categoryTree", "1358216805"],
        ["ext.categoryTree.css", "1357155367"],
        ["ext.nuke", "1357155502"],
        ["ext.centralauth", "1358217212"],
        ["ext.centralauth.noflash", "1357155379"],
        ["ext.centralauth.globalusers", "1357155379"],
        ["ext.centralauth.globalgrouppermissions", "1357155379"],
        ["ext.centralNotice.interface", "1357155383", ["jquery.ui.datepicker"]],
        ["ext.centralNotice.bannerStats", "1357155383"],
        ["ext.centralNotice.bannerController", "1357155383"],
        ["ext.collection.jquery.jstorage", "1357155399", ["jquery.json"]],
        ["ext.collection.suggest", "1357155399", ["ext.collection.bookcreator"]],
        ["ext.collection",
            "1357155399", ["ext.collection.bookcreator", "jquery.ui.sortable"]],
        ["ext.collection.bookcreator", "1357155399", ["ext.collection.jquery.jstorage"]],
        ["ext.collection.checkLoadFromLocalStorage", "1357155399", ["ext.collection.jquery.jstorage"]],
        ["ext.abuseFilter", "1357155338"],
        ["ext.abuseFilter.edit", "1358220631", ["mediawiki.util", "jquery.textSelection", "jquery.spinner"]],
        ["ext.abuseFilter.tools", "1357155338", ["mediawiki.util", "jquery.spinner"]],
        ["ext.abuseFilter.examine", "1358217601", ["mediawiki.util"]],
        ["ext.vector.collapsibleNav", "1358216813", ["mediawiki.util", "jquery.client", "jquery.cookie", "jquery.tabIndex"], "ext.vector"],
        ["ext.vector.collapsibleTabs", "1357155608", ["jquery.collapsibleTabs", "jquery.delayedBind"], "ext.vector"],
        ["ext.vector.editWarning", "1358216813", [], "ext.vector"],
        ["ext.vector.expandableSearch", "1357155608", ["jquery.client", "jquery.expandableField", "jquery.delayedBind"], "ext.vector"],
        ["ext.vector.footerCleanup", "1358216851", ["mediawiki.jqueryMsg", "jquery.cookie"],
            "ext.vector"],
        ["ext.vector.sectionEditLinks", "1357155608", ["jquery.cookie", "jquery.clickTracking"], "ext.vector"],
        ["contentCollector", "1357155652", [], "ext.wikiEditor"],
        ["jquery.wikiEditor", "1358216799", ["jquery.client", "jquery.textSelection", "jquery.delayedBind"], "ext.wikiEditor"],
        ["jquery.wikiEditor.iframe", "1357155653", ["jquery.wikiEditor", "contentCollector"], "ext.wikiEditor"],
        ["jquery.wikiEditor.dialogs", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.toolbar", "jquery.ui.dialog", "jquery.ui.button", "jquery.ui.draggable", "jquery.ui.resizable", "jquery.tabIndex"], "ext.wikiEditor"],
        ["jquery.wikiEditor.dialogs.config", "1358216799", ["jquery.wikiEditor", "jquery.wikiEditor.dialogs", "jquery.wikiEditor.toolbar.i18n", "jquery.suggestions", "mediawiki.Title", "mediawiki.jqueryMsg"], "ext.wikiEditor"],
        ["jquery.wikiEditor.highlight", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.iframe"], "ext.wikiEditor"],
        ["jquery.wikiEditor.preview", "1357155653", ["jquery.wikiEditor"], "ext.wikiEditor"],
        [
            "jquery.wikiEditor.previewDialog", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.dialogs"], "ext.wikiEditor"],
        ["jquery.wikiEditor.publish", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.dialogs"], "ext.wikiEditor"],
        ["jquery.wikiEditor.templateEditor", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.iframe", "jquery.wikiEditor.dialogs"], "ext.wikiEditor"],
        ["jquery.wikiEditor.templates", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.iframe"], "ext.wikiEditor"],
        ["jquery.wikiEditor.toc", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.iframe", "jquery.ui.draggable", "jquery.ui.resizable", "jquery.autoEllipsis", "jquery.color"], "ext.wikiEditor"],
        ["jquery.wikiEditor.toolbar", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.toolbar.i18n"], "ext.wikiEditor"],
        ["jquery.wikiEditor.toolbar.config", "1357155653", ["jquery.wikiEditor", "jquery.wikiEditor.toolbar.i18n", "jquery.wikiEditor.toolbar", "jquery.cookie", "jquery.async"], "ext.wikiEditor"],
        ["jquery.wikiEditor.toolbar.i18n",
            "1347062400", [], "ext.wikiEditor"],
        ["ext.wikiEditor", "1357155652", ["jquery.wikiEditor"], "ext.wikiEditor"],
        ["ext.wikiEditor.dialogs", "1357155652", ["ext.wikiEditor", "ext.wikiEditor.toolbar", "jquery.wikiEditor.dialogs", "jquery.wikiEditor.dialogs.config"], "ext.wikiEditor"],
        ["ext.wikiEditor.highlight", "1357155652", ["ext.wikiEditor", "jquery.wikiEditor.highlight"], "ext.wikiEditor"],
        ["ext.wikiEditor.preview", "1357155652", ["ext.wikiEditor", "jquery.wikiEditor.preview"], "ext.wikiEditor"],
        ["ext.wikiEditor.previewDialog", "1357155652", ["ext.wikiEditor", "jquery.wikiEditor.previewDialog"], "ext.wikiEditor"],
        ["ext.wikiEditor.publish", "1357155652", ["ext.wikiEditor", "jquery.wikiEditor.publish"], "ext.wikiEditor"],
        ["ext.wikiEditor.templateEditor", "1357155652", ["ext.wikiEditor", "ext.wikiEditor.highlight", "jquery.wikiEditor.templateEditor"], "ext.wikiEditor"],
        ["ext.wikiEditor.templates", "1357155652", ["ext.wikiEditor", "ext.wikiEditor.highlight", "jquery.wikiEditor.templates"], "ext.wikiEditor"],
        [
            "ext.wikiEditor.toc", "1357155652", ["ext.wikiEditor", "ext.wikiEditor.highlight", "jquery.wikiEditor.toc"], "ext.wikiEditor"],
        ["ext.wikiEditor.tests.toolbar", "1357155652", ["ext.wikiEditor.toolbar"], "ext.wikiEditor"],
        ["ext.wikiEditor.toolbar", "1357155652", ["ext.wikiEditor", "jquery.wikiEditor.toolbar", "jquery.wikiEditor.toolbar.config"], "ext.wikiEditor"],
        ["ext.wikiEditor.toolbar.hideSig", "1357155652", [], "ext.wikiEditor"],
        ["jquery.clickTracking", "1357155389", ["jquery.cookie", "mediawiki.util"]],
        ["ext.clickTrackingSidebar", "1357155389", ["jquery.clickTracking"]],
        ["ext.UserBuckets", "1357155389", ["jquery.clickTracking", "jquery.json", "jquery.cookie"]],
        ["rangy", "1357155627", [], "ext.visualEditor"],
        ["jquery.multiSuggest", "1357155627", [], "ext.visualEditor"],
        ["jquery.visibleText", "1357155627", [], "ext.visualEditor"],
        ["ext.visualEditor.editPageInit", "1347062400", ["ext.visualEditor.viewPageTarget"], "ext.visualEditor"],
        ["ext.visualEditor.viewPageTarget.icons-raster", "1357155628", [], "ext.visualEditor"],
        [
            "ext.visualEditor.viewPageTarget.icons-vector", "1357155628", [], "ext.visualEditor"],
        ["ext.visualEditor.viewPageTarget", "1358216912", ["ext.visualEditor.base", "jquery.byteLength", "jquery.byteLimit", "jquery.client", "jquery.placeholder", "jquery.visibleText", "mediawiki.jqueryMsg", "mediawiki.Title", "mediawiki.Uri", "mediawiki.user", "mediawiki.util", "mediawiki.notify", "mediawiki.feedback", "user.options", "user.tokens"], "ext.visualEditor"],
        ["ext.visualEditor.base", "1357155628", [], "ext.visualEditor"],
        ["ext.visualEditor.specialMessages", "1358217416", ["ext.visualEditor.base"]],
        ["ext.visualEditor.core", "1358217416", ["jquery", "rangy", "ext.visualEditor.base", "mediawiki.Title", "jquery.autoEllipsis", "jquery.multiSuggest"], "ext.visualEditor"],
        ["ext.visualEditor.icons-raster", "1357155628", [], "ext.visualEditor"],
        ["ext.visualEditor.icons-vector", "1357155628", [], "ext.visualEditor"],
        ["ext.wikiLove.icon", "1357155654"],
        ["ext.wikiLove.defaultOptions", "1358216801"],
        ["ext.wikiLove.startup", "1358216801", [
            "ext.wikiLove.defaultOptions", "jquery.ui.dialog", "jquery.ui.button", "jquery.localize", "jquery.elastic"]],
        ["ext.wikiLove.local", "1358216825"],
        ["ext.wikiLove.init", "1357155654", ["ext.wikiLove.startup"]],
        ["jquery.elastic", "1357155497"],
        ["ext.markAsHelpful", "1357155483", ["mediawiki.util"]],
        ["ext.moodBar.init", "1358216813", ["jquery.cookie", "jquery.client", "mediawiki.util", "mediawiki.user"]],
        ["ext.moodBar.tooltip", "1358216813", ["jquery.cookie", "ext.moodBar.init"]],
        ["jquery.NobleCount", "1357155497"],
        ["ext.moodBar.core", "1358216813", ["mediawiki.util", "mediawiki.jqueryMsg", "ext.moodBar.init", "jquery.localize", "jquery.NobleCount", "jquery.moodBar", "mediawiki.jqueryMsg"]],
        ["ext.moodBar.dashboard", "1358218728", ["mediawiki.util", "user.tokens", "jquery.NobleCount", "jquery.elastic"]],
        ["ext.moodBar.dashboard.styles", "1357155497"],
        ["jquery.moodBar", "1357155497", ["mediawiki.util"]],
        ["mobile.site", "1357499337", [], "site"],
        ["mobile.desktop", "1357690202", ["jquery.cookie"]],
        ["ext.math.mathjax", "1357155485", [],
            "ext.math.mathjax"],
        ["ext.math.mathjax.enabler", "1357155487"],
        ["ext.babel", "1357155365"],
        ["ext.apiSandbox", "1358225181", ["mediawiki.util", "jquery.ui.button"]],
        ["ext.pageTriage.external", "1358216792"],
        ["ext.pageTriage.util", "1358216792"],
        ["ext.pageTriage.models", "1358216792", ["mediawiki.Title", "mediawiki.user", "ext.pageTriage.external"]],
        ["jquery.tipoff", "1357155515"],
        ["ext.pageTriage.views.list", "1358216963", ["mediawiki.jqueryMsg", "ext.pageTriage.models", "ext.pageTriage.util", "jquery.tipoff", "jquery.ui.button", "jquery.spinner"]],
        ["ext.pageTriage.views.toolbar", "1358216792", ["mediawiki.jqueryMsg", "ext.pageTriage.models", "ext.pageTriage.util", "jquery.badge", "jquery.ui.button", "jquery.ui.draggable", "jquery.spinner", "ext.pageTriage.externalTagsOptions", "ext.pageTriage.externalDeletionTagsOptions"]],
        ["ext.pageTriage.defaultTagsOptions", "1358216792"],
        ["ext.pageTriage.externalTagsOptions", "1358216792", ["ext.pageTriage.defaultTagsOptions"]],
        ["ext.pageTriage.defaultDeletionTagsOptions",
            "1358216792", ["mediawiki.Title"]],
        ["ext.pageTriage.externalDeletionTagsOptions", "1358216792", ["ext.pageTriage.defaultDeletionTagsOptions"]],
        ["ext.pageTriage.toolbarStartup", "1357155515"],
        ["ext.pageTriage.article", "1357155515"],
        ["ext.interwiki.specialpage", "1357155469", ["jquery.makeCollapsible"]],
        ["ep.core", "1357155434", ["mediawiki.jqueryMsg", "mediawiki.language"]],
        ["ep.api", "1357155434", ["mediawiki.user", "ep.core"]],
        ["ep.pager", "1358218705", ["ep.api", "mediawiki.jqueryMsg", "jquery.ui.dialog"]],
        ["ep.pager.course", "1347062400", ["ep.pager"]],
        ["ep.pager.org", "1347062400", ["ep.pager"]],
        ["ep.datepicker", "1357155434", ["jquery.ui.datepicker"]],
        ["ep.combobox", "1357155434", ["jquery.ui.core", "jquery.ui.widget", "jquery.ui.autocomplete"]],
        ["ep.formpage", "1357155434", ["jquery.ui.button", "ext.wikiEditor.toolbar"]],
        ["ep.disenroll", "1357155434", ["jquery.ui.button"]],
        ["ep.ambprofile", "1357155434", ["jquery.ui.button", "ep.imageinput", "ext.wikiEditor.toolbar"]],
        ["ep.imageinput", "1357155434", [
            "jquery.ui.autocomplete"]],
        ["ep.articletable", "1358218308", ["jquery.ui.button", "jquery.ui.dialog", "jquery.ui.autocomplete", "ep.core"]],
        ["ep.addorg", "1357155434"],
        ["ep.addcourse", "1357583806"],
        ["ep.timeline", "1357155434"],
        ["ep.studentactivity", "1357155434"],
        ["ep.enlist", "1358217417", ["mediawiki.user", "jquery.ui.dialog", "ep.core", "ep.api", "jquery.ui.autocomplete"]],
        ["ext.wikimediaShopLink.core", "1358216791", ["mediawiki.util"]],
        ["ext.Experiments.eventlog", "1357155429"],
        ["schema.OpenTask", "1347062400", ["ext.eventLogging"]],
        ["schema.CommunityPortal", "1347062400", ["ext.eventLogging"]],
        ["schema.GettingStarted", "1347062400", ["ext.eventLogging"]],
        ["schema.AccountCreation", "1347062400", ["ext.eventLogging"]],
        ["ext.Experiments.lib", "1357155429", ["jquery.cookie", "jquery.json", "mediawiki.user", "ext.UserBuckets"]],
        ["ext.Experiments.experiments", "1357852894", ["ext.Experiments.lib", "schema.CommunityPortal", "schema.GettingStarted", "ext.postEdit"]],
        ["ext.Experiments.acux", "1358216793", [
            "ext.Experiments.lib", "jquery.tipsy", "mediawiki.jqueryMsg", "schema.AccountCreation"]],
        ["ext.postEdit", "1358216792", ["jquery.cookie"]],
        ["ext.gettingstarted", "1357155458"],
        ["ext.gettingstarted.accountcreation", "1358216850", ["ext.gettingstarted", "mediawiki.util"]],
        ["ext.eventLogging", "1357852900", ["jquery.json", "mediawiki.util"]],
        ["ext.eventLogging.jsonSchema", "1357155436"],
        ["ext.TemplateSandbox", "1357155553"],
        ["ext.checkUser", "1357155386", ["mediawiki.util"]],
        ["mw.PopUpMediaTransform", "1357155557", ["jquery.ui.dialog"]],
        ["embedPlayerIframeStyle", "1357155557"],
        ["ext.tmh.transcodetable", "1358217413"],
        ["mw.MediaWikiPlayerSupport", "1357155557", ["mw.Api"]]
    ]);
    mw.config.set({
        "wgLoadScript": "//bits.wikimedia.org/en.wikipedia.org/load.php",
        "debug": false,
        "skin": "vector",
        "stylepath": "//bits.wikimedia.org/static-1.21wmf7/skins",
        "wgUrlProtocols": "http\\:\\/\\/|https\\:\\/\\/|ftp\\:\\/\\/|irc\\:\\/\\/|ircs\\:\\/\\/|gopher\\:\\/\\/|telnet\\:\\/\\/|nntp\\:\\/\\/|worldwind\\:\\/\\/|mailto\\:|news\\:|svn\\:\\/\\/|git\\:\\/\\/|mms\\:\\/\\/|\\/\\/",
        "wgArticlePath": "/wiki/$1",
        "wgScriptPath": "/w",
        "wgScriptExtension": ".php",
        "wgScript": "/w/index.php",
        "wgVariantArticlePath": false,
        "wgActionPaths": {},
        "wgServer": "//en.wikipedia.org",
        "wgUserLanguage": "en",
        "wgContentLanguage": "en",
        "wgVersion": "1.21wmf7",
        "wgEnableAPI": true,
        "wgEnableWriteAPI": true,
        "wgMainPageTitle": "Main Page",
        "wgFormattedNamespaces": {
            "-2": "Media",
            "-1": "Special",
            "0": "",
            "1": "Talk",
            "2": "User",
            "3": "User talk",
            "4": "Wikipedia",
            "5": "Wikipedia talk",
            "6": "File",
            "7": "File talk",
            "8": "MediaWiki",
            "9": "MediaWiki talk",
            "10": "Template",
            "11": "Template talk",
            "12": "Help",
            "13": "Help talk",
            "14": "Category",
            "15": "Category talk",
            "100": "Portal",
            "101": "Portal talk",
            "108": "Book",
            "109": "Book talk",
            "446": "Education Program",
            "447": "Education Program talk",
            "710": "TimedText",
            "711": "TimedText talk"
        },
        "wgNamespaceIds": {
            "media": -2,
            "special": -1,
            "": 0,
            "talk": 1,
            "user": 2,
            "user_talk": 3,
            "wikipedia": 4,
            "wikipedia_talk": 5,
            "file": 6,
            "file_talk": 7,
            "mediawiki": 8,
            "mediawiki_talk": 9,
            "template": 10,
            "template_talk": 11,
            "help": 12,
            "help_talk": 13,
            "category": 14,
            "category_talk": 15,
            "portal": 100,
            "portal_talk": 101,
            "book": 108,
            "book_talk": 109,
            "education_program": 446,
            "education_program_talk": 447,
            "timedtext": 710,
            "timedtext_talk": 711,
            "wp": 4,
            "wt": 5,
            "image": 6,
            "image_talk": 7,
            "project": 4,
            "project_talk": 5
        },
        "wgSiteName": "Wikipedia",
        "wgFileExtensions": ["png", "gif", "jpg", "jpeg", "xcf", "pdf", "mid", "ogg", "ogv", "svg", "djvu", "tiff", "tif", "ogg", "ogv", "oga", "webm"],
        "wgDBname": "enwiki",
        "wgFileCanRotate": true,
        "wgAvailableSkins": {
            "chick": "Chick",
            "simple": "Simple",
            "standard": "Standard",
            "nostalgia": "Nostalgia",
            "myskin": "MySkin",
            "cologneblue": "CologneBlue",
            "monobook": "MonoBook",
            "vector": "Vector",
            "modern": "Modern"
        },
        "wgExtensionAssetsPath": "//bits.wikimedia.org/static-1.21wmf7/extensions",
        "wgCookiePrefix": "enwiki",
        "wgResourceLoaderMaxQueryLength": -1,
        "wgCaseSensitiveNamespaces": [],
        "EmbedPlayer.DirectFileLinkWarning": true,
        "EmbedPlayer.EnableOptionsMenu": true,
        "EmbedPlayer.DisableJava": false,
        "TimedText.ShowInterface": "always",
        "TimedText.ShowAddTextLink": true,
        "EmbedPlayer.WebPath": "//bits.wikimedia.org/static-1.21wmf7/extensions/TimedMediaHandler/MwEmbedModules/EmbedPlayer",
        "wgCortadoJarFile": false,
        "AjaxRequestTimeout": 30,
        "MediaWiki.DefaultProvider": "local",
        "MediaWiki.ApiProviders": {
            "wikimediacommons": {
                "url": "//commons.wikimedia.org/w/api.php"
            }
        },
        "MediaWiki.ApiPostActions": ["login", "purge", "rollback", "delete", "undelete", "protect", "block", "unblock", "move", "edit", "upload", "emailuser", "import", "userrights"],
        "EmbedPlayer.OverlayControls": true,
        "EmbedPlayer.CodecPreference": ["webm", "h264", "ogg"],
        "EmbedPlayer.DisableVideoTagSupport": false,
        "EmbedPlayer.DisableHTML5FlashFallback": false,
        "EmbedPlayer.ReplaceSources": null,
        "EmbedPlayer.EnableFlavorSelector": false,
        "EmbedPlayer.EnableIpadHTMLControls": true,
        "EmbedPlayer.WebKitPlaysInline": false,
        "EmbedPlayer.EnableIpadNativeFullscreen": false,
        "EmbedPlayer.iPhoneShowHTMLPlayScreen": true,
        "EmbedPlayer.ForceLargeReplayButton": false,
        "EmbedPlayer.LibraryPage": "http://www.kaltura.org/project/HTML5_Video_Media_JavaScript_Library",
        "EmbedPlayer.RewriteSelector": "video,audio,playlist",
        "EmbedPlayer.DefaultSize": "400x300",
        "EmbedPlayer.ControlsHeight": 31,
        "EmbedPlayer.TimeDisplayWidth": 85,
        "EmbedPlayer.KalturaAttribution": true,
        "EmbedPlayer.AttributionButton": {
            "title": "Kaltura html5 video library",
            "href": "http://www.kaltura.com",
            "class": "kaltura-icon",
            "style": [],
            "iconurl": false
        },
        "EmbedPlayer.EnableRightClick": true,
        "EmbedPlayer.EnabledOptionsMenuItems": ["playerSelect", "download", "share", "aboutPlayerLibrary"],
        "EmbedPlayer.WaitForMeta": true,
        "EmbedPlayer.ShowNativeWarning": true,
        "EmbedPlayer.ShowPlayerAlerts": true,
        "EmbedPlayer.EnableFullscreen": true,
        "EmbedPlayer.EnableTimeDisplay": true,
        "EmbedPlayer.EnableVolumeControl": true,
        "EmbedPlayer.NewWindowFullscreen": false,
        "EmbedPlayer.FullscreenTip": true,
        "EmbedPlayer.FirefoxLink": "http://www.mozilla.com/en-US/firefox/upgrade.html?from=mwEmbed",
        "EmbedPlayer.NativeControls": false,
        "EmbedPlayer.NativeControlsMobileSafari": true,
        "EmbedPlayer.FullScreenZIndex": 999998,
        "EmbedPlayer.ShareEmbedMode": "iframe",
        "EmbedPlayer.SkinList": ["mvpcf", "kskin"],
        "EmbedPlayer.DefaultSkin": "mvpcf",
        "EmbedPlayer.MonitorRate": 250,
        "EmbedPlayer.UseFlashOnAndroid": false,
        "EmbedPlayer.EnableURLTimeEncoding": "flash",
        "EmbedPLayer.IFramePlayer.DomainWhiteList": "*",
        "EmbedPlayer.EnableIframeApi": true,
        "EmbedPlayer.PageDomainIframe": true,
        "EmbedPlayer.NotPlayableDownloadLink": true,
        "EmbedPlayer.BlackPixel": "data:image/png,%89PNG%0D%0A%1A%0A%00%00%00%0DIHDR%00%00%00%01%00%00%00%01%08%02%00%00%00%90wS%DE%00%00%00%01sRGB%00%AE%CE%1C%E9%00%00%00%09pHYs%00%00%0B%13%00%00%0B%13%01%00%9A%9C%18%00%00%00%07tIME%07%DB%0B%0A%17%041%80%9B%E7%F2%00%00%00%19tEXtComment%00Created%20with%20GIMPW%81%0E%17%00%00%00%0CIDAT%08%D7c%60%60%60%00%00%00%04%00%01\'4\'%0A%00%00%00%00IEND%AEB%60%82",
        "TimedText.ShowRequestTranscript": false,
        "TimedText.NeedsTranscriptCategory": "Videos needing subtitles",
        "TimedText.BottomPadding": 10,
        "TimedText.BelowVideoBlackBoxHeight": 40,
        "wgCollectionVersion": "1.6.1",
        "wgCollapsibleNavBucketTest": false,
        "wgCollapsibleNavForceNewVersion": false,
        "wgWikiEditorToolbarClickTracking": false,
        "wgWikiEditorMagicWords": {
            "redirect": "#REDIRECT",
            "img_right": "right",
            "img_left": "left",
            "img_none": "none",
            "img_center": "center",
            "img_thumbnail": "thumbnail",
            "img_framed": "framed",
            "img_frameless": "frameless"
        },
        "wgArticleFeedbackSMaxage": 2592000,
        "wgArticleFeedbackCategories": ["Article Feedback Pilot",
            "Article Feedback", "Article Feedback Additional Articles"],
        "wgArticleFeedbackBlacklistCategories": ["Article Feedback Blacklist", "Article Feedback 5", "Article Feedback 5 Additional Articles"],
        "wgArticleFeedbackLotteryOdds": 90,
        "wgArticleFeedbackTracking": {
            "buckets": {
                "track": 100,
                "ignore": 0
            },
            "version": 10,
            "expires": 30,
            "tracked": false
        },
        "wgArticleFeedbackOptions": {
            "buckets": {
                "show": 100,
                "hide": 0
            },
            "version": 8,
            "expires": 30,
            "tracked": false
        },
        "wgArticleFeedbackNamespaces": [0],
        "wgArticleFeedbackWhatsThisPage": "Wikipedia:Article Feedback Tool",
        "wgArticleFeedbackRatingTypesFlipped": {
            "trustworthy": 1,
            "objective": 2,
            "complete": 3,
            "wellwritten": 4
        },
        "wgArticleFeedbackv5SMaxage": 2592000,
        "wgArticleFeedbackv5Categories": ["Article_Feedback_5", "Article_Feedback_5_Additional_Articles"],
        "wgArticleFeedbackv5BlacklistCategories": ["Article_Feedback_Blacklist"],
        "wgArticleFeedbackv5Debug": false,
        "wgArticleFeedbackv5Tracking": {
            "buckets": {
                "ignore": 100,
                "track": 0,
                "track-front": 0,
                "track-special": 0
            },
            "version": 11,
            "expires": 30,
            "tracked": false
        },
        "wgArticleFeedbackv5LinkBuckets": {
            "buckets": {
                "X": 100,
                "A": 0,
                "B": 0,
                "C": 0,
                "D": 0,
                "E": 0,
                "F": 0,
                "G": 0,
                "H": 0
            },
            "version": 5,
            "expires": 30,
            "tracked": false
        },
        "wgArticleFeedbackv5Namespaces": [0, 12, 4],
        "wgArticleFeedbackv5LearnToEdit": "//en.wikipedia.org/wiki/Wikipedia:Tutorial",
        "wgArticleFeedbackv5SurveyUrls": {
            "1": "https://www.surveymonkey.com/s/aft5-1",
            "2": "https://www.surveymonkey.com/s/aft5-2",
            "3": "https://www.surveymonkey.com/s/aft5-3",
            "6": "https://www.surveymonkey.com/s/aft5-6"
        },
        "wgArticleFeedbackv5InitialFeedbackPostCountToDisplay": 50,
        "wgArticleFeedbackv5ThrottleThresholdPostsPerHour": 20,
        "wgArticleFeedbackv5SpecialUrl": "/wiki/Special:ArticleFeedbackv5",
        "wgArticleFeedbackv5SpecialWatchlistUrl": "/wiki/Special:ArticleFeedbackv5Watchlist",
        "wgArticleFeedbackv5TalkPageLink": true,
        "wgArticleFeedbackv5WatchlistLink": true,
        "wgArticleFeedbackv5DefaultSorts": {
            "abusive": ["age", "desc"],
            "all": ["age", "desc"],
            "comment": ["age", "desc"],
            "declined": ["age", "desc"],
            "featured": ["relevance", "asc"],
            "helpful": ["helpful", "desc"],
            "hidden": ["age", "desc"],
            "id": ["age", "desc"],
            "notdeleted": ["age", "desc"],
            "oversighted": ["age", "desc"],
            "relevant": ["relevance", "asc"],
            "requested": ["age", "desc"],
            "resolved": ["age", "desc"],
            "unfeatured": ["relevance", "desc"],
            "unhelpful": ["helpful", "asc"],
            "unhidden": ["age", "desc"],
            "unoversighted": ["age", "desc"],
            "unrequested": ["age", "desc"],
            "unresolved": ["age", "desc"],
            "visible": ["age", "desc"]
        },
        "wgArticleFeedbackv5LotteryOdds": {
            "0": 10,
            "12": 100
        },
        "wgArticleFeedbackv5MaxCommentLength": 5000,
        "wgArticleFeedbackv5DisplayBuckets": {
            "buckets": {
                "0": 0,
                "1": 0,
                "4": 0,
                "6": 100
            },
            "version": 6,
            "expires": 30,
            "tracked": false
        },
        "wgArticleFeedbackv5CTABuckets": {
            "buckets": {
                "0": 0,
                "1": 0,
                "2": 0,
                "3": 0,
                "4": 90,
                "5": 9,
                "6": 1
            },
            "version": 7,
            "expires": 0,
            "tracked": false
        },
        "mbConfig": {
            "validTypes": ["happy", "sad", "confused"],
            "userBuckets": [],
            "feedbackDashboardUrl": "/wiki/Special:FeedbackDashboard",
            "bucketConfig": {
                "buckets": {
                    "feedback": 0,
                    "share": 0,
                    "editing": 100
                },
                "version": 3,
                "expires": 30
            },
            "infoUrl": "//en.wikipedia.org/wiki/Wikipedia:New_editor_feedback",
            "privacyUrl": "//wikimediafoundation.org/wiki/Feedback_policy",
            "disableExpiration": 365
        },
        "wgPageTriageCurationModules": {
            "articleInfo": {
                "helplink": "//en.wikipedia.org/wiki/Wikipedia:Page_Curation/Help#PageInfo",
                "namespace": [0, 2]
            },
            "wikiLove": {
                "helplink": "//en.wikipedia.org/wiki/Wikipedia:Page_Curation/Help#WikiLove",
                "namespace": [0, 2]
            },
            "mark": {
                "helplink": "//en.wikipedia.org/wiki/Wikipedia:Page_Curation/Help#MarkReviewed",
                "namespace": [0, 2],
                "note": [0]
            },
            "tags": {
                "helplink": "//en.wikipedia.org/wiki/Wikipedia:Page_Curation/Help#AddTags",
                "namespace": [0]
            },
            "delete": {
                "helplink": "//en.wikipedia.org/wiki/Wikipedia:Page_Curation/Help#MarkDeletion",
                "namespace": [0, 2]
            }
        },
        "wgPageTriageNamespaces": [0, 2],
        "wgTalkPageNoteTemplate": {
            "Mark": "Reviewednote-NPF",
            "UnMark": {
                "note": "Unreviewednote-NPF",
                "nonote": "Unreviewednonote-NPF"
            },
            "Tags": "Taggednote-NPF"
        },
        "wmfshopLinkTarget": "//shop.wikimedia.org",
        "wmfshopLinkCountries": ["US", "VI", "UM", "PR", "CA", "MX"],
        "wgMinimalPasswordLength": 1,
        "wgEventLoggingBaseUri": "//bits.wikimedia.org/event.gif",
        "wgNoticeFundraisingUrl": "https://donate.wikimedia.org/wiki/Special:LandingCheck",
        "wgCentralPagePath": "//meta.wikimedia.org/w/index.php",
        "wgNoticeBannerListLoader": "Special:BannerListLoader",
        "wgCentralBannerDispatcher": "//meta.wikimedia.org/wiki/Special:BannerRandom",
        "wgCentralBannerRecorder": "//meta.wikimedia.org/wiki/Special:RecordImpression",
        "wgNoticeXXCountries": ["XX", "EU", "AP", "A1", "A2", "O1"],
        "wgNoticeNumberOfBuckets": 4,
        "wgNoticeBucketExpiry": 7,
        "wgNoticeNumberOfControllerBuckets": 2,
        "wgCookiePath": "/",
        "wgMFStopRedirectCookieHost": ".wikipedia.org"
    });
};

if (isCompatible()) {
  console.log("before", document.documentElement.outerHTML);
  document.write("\x3cscript src=\"//bits.wikimedia.org/en.wikipedia.org/load.php?debug=false\x26amp;lang=en\x26amp;modules=jquery%2Cmediawiki%2CSpinner%7Cjquery.triggerQueueCallback%2CloadingSpinner%2CmwEmbedUtil%7Cmw.MwEmbedSupport\x26amp;only=scripts\x26amp;skin=vector\x26amp;version=20130102T193818Z\"\x3e\x3c/script\x3e");
  console.log("after", document.documentElement.outerHTML);
}

delete
isCompatible;
/* cache key: enwiki:resourceloader:filter:minify-js:7:892e16dd7f5b19f76442d1f1ebc35778 */
