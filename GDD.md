nter;
        gap: 8px;
        background: rgba(255, 255, 255, 0.15);
        border: 1px solid rgba(255, 255, 255, 0.25);
        padding: 8px 16px;
        border-radius: 20px;
        font-size: 11px;
        font-weight: 600;
        color: var(--sl-color-neutral-0);
        width: fit-content;
        text-transform: uppercase;
        letter-spacing: 0.8px;
        margin-bottom: 16px;
        backdrop-filter: blur(8px);
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .badge-icon {
        font-size: 14px;
    }

    /* Button area - add theme decoration */
    .store-actions {
        display: flex;
        gap: 12px;
        flex-wrap: wrap;
        position: relative;
    }

    /* Button area decorative glow effect */
    .store-actions::before {
        content: "";
        position: absolute;
        left: -16px;
        top: 50%;
        transform: translateY(-50%);
        width: 12px;
        height: 12px;
        background: radial-gradient(circle, rgba(0, 212, 255, 0.8) 0%, transparent 70%);
        border-radius: 50%;
        animation: buttonGlow 2s ease-in-out infinite;
    }

    @keyframes buttonGlow {
        0%, 100% {
            opacity: 0.5;
            transform: translateY(-50%) scale(1);
        }
        50% {
            opacity: 1;
            transform: translateY(-50%) scale(1.5);
        }
    }

    .promo-btn {
        width: max-content;
        height: 48px;
    }

    .promo-btn::part(label) {
        align-self: center;
        font-size: 18px;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .promo-btn .logo {
        width: 24px;
        vertical-align: middle;
        display: inline-block;
    }

    .promo-btn {
        --buy-btn-color: rgba(255, 255, 255, 0.2);
        --buy-btn-text-color: var(--sl-color-neutral-0);
        --buy-btn-box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        --buy-btn-hover-color: rgba(255, 255, 255, 0.28);
    }

    .store-pdp-button::part(base) {
        background: rgba(255, 255, 255, 0.12);
        border: none;
        backdrop-filter: blur(8px);
        transition: all 0.2s ease;
    }

    .store-pdp-button::part(base):hover {
        background: rgba(255, 255, 255, 0.18);
        border: none;
        transform: translateY(-1px);
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    /* Right visual area */
    .store-visual-section {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 40px;
        position: relative;
        transform: translateY(20px); /* Adjust downward to balance visual center */
    }

    .store-icon-showcase {
        position: relative;
        display: flex;
        justify-content: center;
        align-items: center;
    }

    /* Background ring animation */
    .icon-background-ring {
        position: absolute;
        border: 2px solid rgba(255, 255, 255, 0.2);
        border-radius: 50%;
        animation: rotate 20s linear infinite;
    }

    .icon-background-ring {
        width: 200px;
        height: 200px;
    }

    .ring-2 {
        width: 280px;
        height: 280px;
        animation-direction: reverse;
        animation-duration: 30s;
        border-color: rgba(255, 255, 255, 0.1);
    }

    @keyframes rotate {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
    }

    .store-icon-container {
        position: relative;
        display: flex;
        justify-content: center;
        align-items: center;
        width: 140px;
        height: 140px;
        background: linear-gradient(135deg, #ffffff, #f8f9fa);
        border-radius: 32px;
        box-shadow:
            0 20px 40px rgba(0, 0, 0, 0.15),
            0 10px 20px rgba(0, 0, 0, 0.1),
            inset 0 1px 0 rgba(255, 255, 255, 0.8);
        animation: iconBounce 4s ease-in-out infinite;
        z-index: 2;
    }

    @keyframes iconBounce {
        0%, 100% { transform: translateY(0px) scale(1); }
        50% { transform: translateY(-10px) scale(1.05); }
    }

    .store-icon-glow {
        position: absolute;
        top: -15px;
        left: -15px;
        right: -15px;
        bottom: -15px;
        border-radius: 40px;
        opacity: 0.4;
        filter: blur(20px);
        animation: glowPulse 3s ease-in-out infinite;
    }

    @keyframes glowPulse {
        0%, 100% { opacity: 0.4; transform: scale(1); }
        50% { opacity: 0.6; transform: scale(1.1); }
    }

    .store-logo {
        width: 80px;
        height: 80px;
        object-fit: contain;
        z-index: 1;
        position: relative;
        filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.1));
    }

    /* Floating small icons */
    .floating-icons {
        position: absolute;
        width: 300px;
        height: 300px;
        pointer-events: none;
    }

    .mini-icon {
        position: absolute;
        font-size: 20px;
        background: rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        padding: 8px;
        border-radius: 50%;
        animation: floatAround 8s ease-in-out infinite;
    }

    .icon-1 {
        top: 10%;
        left: 20%;
        animation-delay: 0s;
    }

    .icon-2 {
        top: 20%;
        right: 10%;
        animation-delay: 1s;
    }

    .icon-3 {
        bottom: 30%;
        left: 10%;
        animation-delay: 2s;
    }

    .icon-4 {
        bottom: 20%;
        right: 20%;
        animation-delay: 3s;
    }

    .icon-5 {
        top: 40%;
        left: 0%;
        animation-delay: 1s;
    }

    .icon-6 {
        top: 40%;
        right: 5%;
        animation-delay: 5s;
    }

    @keyframes floatAround {
        0%, 100% {
            transform: translateY(0px) translateX(0px) rotate(0deg);
        }
        25% {
            transform: translateY(-15px) translateX(10px) rotate(90deg);
        }
        50% {
            transform: translateY(-30px) translateX(-5px) rotate(180deg);
        }
        75% {
            transform: translateY(-15px) translateX(-10px) rotate(270deg);
        }
    }

    /* Statistics data display */
    .stats-display {
        display: flex;
        gap: 32px;
    }

    .stat-item {
        text-align: center;
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.15);
        padding: 20px 24px;
        border-radius: 16px;
        transition: all 0.3s ease;
    }

    .stat-item:hover {
        background: rgba(255, 255, 255, 0.15);
        transform: translateY(-4px);
    }

    .stat-number {
        font-size: 24px;
        font-weight: 800;
        color: white;
        text-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    }

    .stat-label {
        font-size: 12px;
        color: rgba(255, 255, 255, 0.7);
        margin-top: 4px;
        font-weight: 500;
    }

    .button-icon {
        margin-right: 8px;
        font-size: 16px;
    }

    .button-text {
        font-weight: inherit;
    }

    /* Responsive design - fully reference promo-panel spacing system */
    ${r(a.xxl)} {
        .microsoft-store-content {
            --content-spacing: 92px;
            padding: 44px var(--content-spacing);
            margin-top: 48px;
        }
    }

    ${r(a.xl)} {
        .microsoft-store-content {
            --content-spacing: 72px;
            padding: 40px var(--content-spacing);
            margin-top: 36px;
        }
    }

    ${r(a.lg)} {
        .microsoft-store-section {
            --content-spacing: 48px;
            min-height: 360px;
            margin-top: 24px;
        }

        .microsoft-store-content {
            flex-direction: column;
            gap: 40px;
            padding: 40px;
            text-align: center;
            min-height: 360px;
            align-items: center;
        }

        .store-text-section {
            max-width: 100%;
            justify-content: center;
            margin-bottom: 16px;
        }

        .store-actions {
            justify-content: center;
            margin-bottom: 20px;
        }

        .store-visual-section {
            transform: translateY(0); /* Remove offset in vertical layout */
            margin-top: 8px;
        }

        .floating-icons {
            width: 250px;
            height: 250px;
        }

        .stats-display {
            gap: 24px;
            justify-content: center;
            margin-top: 16px;
        }
    }

    ${r(a.md)} {
        .microsoft-store-section {
            min-height: 340px;
        }

        .microsoft-store-content {
            padding: 36px var(--content-spacing);
            gap: 36px;
            min-height: 340px;
            align-items: center;
        }

        .store-text-section {
            justify-content: center;
            margin-bottom: 16px;
        }

        .store-actions {
            justify-content: center;
            margin-bottom: 20px;
        }

        .promo-panel-content h2,
        .promo-panel-header {
            margin-bottom: 20px;
        }

        .promo-panel-content p,
        .promo-panel-desc {
            margin-bottom: 24px;
        }

        .store-visual-section {
            margin-top: 8px;
        }

        .store-icon-container {
            width: 120px;
            height: 120px;
        }

        .store-logo {
            width: 64px;
            height: 64px;
        }

        .icon-background-ring {
            width: 160px;
            height: 160px;
        }

        .ring-2 {
            width: 220px;
            height: 220px;
        }

        .floating-icons {
            width: 200px;
            height: 200px;
        }

        .stats-display {
            justify-content: center;
            margin-top: 16px;
        }
    }

    ${r(a.sm)} {
        .microsoft-store-section {
            --content-spacing: 28px;
            margin-top: var(--info-card-gap);
            border-radius: 24px;
            min-height: 320px;
        }

        .microsoft-store-content {
            padding: 32px var(--content-spacing);
            gap: 32px;
            min-height: 320px;
            align-items: center;
        }

        .store-text-section {
            justify-content: center;
            margin-bottom: 16px;
        }

        .promo-panel-content h2,
        .promo-panel-header {
            font-size: 24px;
            margin-bottom: 16px;
        }

        .promo-panel-content p,
        .promo-panel-desc {
            font-size: 13px;
            max-width: 100%;
            margin-bottom: 24px;
        }

        .store-actions {
            flex-direction: column;
            width: 100%;
            gap: 12px;
            align-items: center;
            justify-content: center;
            margin-bottom: 20px;
        }

        .promo-btn {
            width: max-content;
        }

        .store-visual-section {
            margin-top: 8px;
        }

        .store-icon-container {
            width: 100px;
            height: 100px;
        }

        .store-logo {
            width: 52px;
            height: 52px;
        }

        .stats-display {
            gap: 20px;
            justify-content: center;
            margin-top: 16px;
            width: calc(100% + 28px);
        }

        .stat-item {
            flex: 1;
            min-width: 0;
            padding: 16px 12px;
        }

        .stat-number {
            font-size: 18px;
            word-wrap: break-word;
            overflow-wrap: break-word;
            hyphens: auto;
        }

        .floating-icons {
            display: none;
        }

        .icon-background-ring {
            width: 120px;
            height: 120px;
        }

        .ring-2 {
            width: 180px;
            height: 180px;
        }

        /* Center button area decorative glow effect on small screens */
        .store-actions::before {
            left: 50%;
            transform: translateX(-50%) translateY(-50%);
            top: -20px;
        }
    }


    /* Container query for very small viewports - stacks stats vertically to prevent cutoff */
    @container (max-width: 360px) {
        .stats-display {
            flex-direction: column;
            gap: 12px;
            width: 100%;
        }
    }


    @media(prefers-color-scheme: dark) {
        .microsoft-store-section {
            background:
                linear-gradient(160deg, rgba(255, 255, 255, 0.03) 0%, transparent 60%),
                linear-gradient(200deg, rgba(255, 255, 255, 0.02) 20%, transparent 70%),
                linear-gradient(94deg, #0f172a 3.61%, #1e3a8a 50%, #3730a3 100.95%);
            border-color: rgba(255, 255, 255, 0.08);
        }

        .promo-panel-content h2,
        .promo-panel-content p,
        .promo-panel-header,
        .promo-panel-desc {
            color: #ffffff;
            text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
        }

        .promo-panel-content h2::after,
        .promo-panel-header::after {
            background: linear-gradient(90deg, rgba(255, 255, 255, 0.8) 0%, rgba(255, 255, 255, 0.3) 100%);
        }


        .promo-btn {
            --buy-btn-text-color: var(--sl-default-white);
            --buy-btn-border-color: transparent;
        }

        .store-pdp-button::part(base) {
            background: rgba(255, 255, 255, 0.15);
            color: #ffffff;
        }

        .store-pdp-button::part(base):hover {
            background: rgba(255, 255, 255, 0.25);
            color: #ffffff;
        }
    }
`;var w=Object.defineProperty,k=Object.getOwnPropertyDescriptor,o=(x,s,c,p)=>{for(var e=p>1?void 0:p?k(s,c):s,d=x.length-1,g;d>=0;d--)(g=x[d])&&(e=(p?g(s,c,e):g(e))||e);return p&&e&&w(s,c,e),e};let t=class extends h{constructor(){super(),this.title="",this.description="",this.href="",this.logoSrc="/assets/icons/logo-256x256.png",this.logoAlt="",this.buttonText=""}connectedCallback(){super.connectedCallback(),m.addImpressionTracking(this)}disconnectedCallback(){super.disconnectedCallback(),m.removeImpressionTracking(this)}render(){return!this.title||!this.description?l``:l`
            <div>
                ${this.renderMicrosoftStorePanel()}
            </div>
        `}renderMicrosoftStorePanel(){return l`
            <div class="microsoft-store-section">
                <!-- Main content area - horizontal layout -->
                <div class="microsoft-store-content">
                    <!-- Left side: text content -->
                    <div class="store-text-section">
                        <div class="promo-panel-content">
                            <h2 class="promo-panel-header">${this.title}</h2>
                            <p class="promo-panel-desc">${this.description}</p>
                            <div class="store-actions">
                                ${this.renderButton()}
                            </div>
                        </div>
                    </div>

                    <!-- Right side: visual elements -->
                    <div class="store-visual-section" role="presentation" aria-hidden="true">
                        <div class="store-icon-showcase">
                            <div class="icon-background-ring"></div>
                            <div class="icon-background-ring ring-2"></div>
                            <div class="store-icon-container">
                                <div class="store-icon-glow"></div>
                                <img src="${this.logoSrc}" alt="${this.logoAlt}" class="store-logo" />
                            </div>
                            <div class="floating-icons">
                                <div class="mini-icon icon-1">ðŸ“±</div>
                                <div class="mini-icon icon-2">ðŸŽ®</div>
                                <div class="mini-icon icon-3">ðŸŽ¨</div>
                                <div class="mini-icon icon-4">ðŸŽµ</div>
                                <div class="mini-icon icon-5">ðŸ’»</div>
                                <div class="mini-icon icon-6">ðŸŽ¬</div>
                            </div>
                        </div>
                        <div class="stats-display">
                            <div class="stat-item">
                                <div class="stat-number">${i.get("AboutPage.AutomaticUpdates")}</div>
                                <div class="stat-label">${i.get("AboutPage.SeamlessExperience")}</div>
                            </div>
                            <div class="stat-item">
                                <div class="stat-number">${i.get("AboutPage.TrustedDownloadText")}</div>
                                <div class="stat-label">${i.get("AboutPage.TrustedDownload")}</div>
                            </div>
                            <div class="stat-item">
                                <div class="stat-number">${i.get("AboutPage.AIIntegratedText")}</div>
                                <div class="stat-label">${i.get("AboutPage.AIIntegrated")}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `}renderButton(){return l`
            <psi-button
                product-id="${f.MicrosoftStorePdpProductId}"
                product-title="Microsoft Store"
                class="promo-btn"
                ocid="${f.OCIDs.ABOUT_PAGE}"
            >
                <img class="logo" src="/assets/icons/light-logo-32x32.svg" loading="eager" alt="" />
                ${this.buttonText}
            </psi-button>
        `}};t.styles=[u,y];o([n({type:String})],t.prototype,"title",2);o([n({type:String})],t.prototype,"description",2);o([n({type:String})],t.prototype,"href",2);o([n({type:String,attribute:"logo-src"})],t.prototype,"logoSrc",2);o([n({type:String,attribute:"logo-alt"})],t.prototype,"logoAlt",2);o([n({type:String,attribute:"button-text"})],t.prototype,"buttonText",2);t=o([v("microsoft-store-panel")],t);export{t as MicrosoftStorePanel};
ØA—Eoúô   s«ù        
	
GET  ( ¬
È  "2
cache-control!public,max-age=31536000,immutable"
content-encodingbr"ì
content-security-policyÐdefault-src 'self' data:;script-src 'self' https://*.clarity.ms https://c.bing.com wcpstatic.microsoft.com js.monitor.azure.com www.microsoft.com get.microsoft.com xvsec.video.microsoft.com bat.bing.com 'unsafe-inline';style-src * 'unsafe-inline';connect-src * data: ms-windows-store:;font-src *;img-src * data: blob:;media-src 'self' blob: https://sfds-production.azurefd.net https://canvasstorageprodtorus.blob.core.windows.net https://cdn-dynmedia-1.microsoft.com https://malibussl-s.akamaihd.net;frame-src * ms-windows-store:;report-uri https://csp.microsoft.com/report/app-store-web-prod"
content-typetext/javascript"%
dateTue, 12 May 2026 10:12:00 GMT"
etagW/"1dcd8e7cba6276a"".
last-modifiedThu, 30 Apr 2026 21:24:58 GMT"
ms-cvetc1Aaxp9Ua6SOgX.0"
permissions-policy	unload=()"@
strict-transport-security#max-age=31536000; includeSubDomains"
varyAccept-Encoding"P
x-azure-refA20260512T1