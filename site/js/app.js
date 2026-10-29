document.addEventListener('DOMContentLoaded', () => {
  // --- 1. Tab Navigation (#hash support) ---
  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanels = document.querySelectorAll('.tab-panel');

  function switchTab(tabId) {
    if (!tabId) tabId = 'overview';
    tabId = tabId.replace('#', '');

    let found = false;
    tabPanels.forEach(panel => {
      if (panel.id === tabId) {
        panel.classList.add('active');
        found = true;
      } else {
        panel.classList.remove('active');
      }
    });

    if (!found) {
      const defaultPanel = document.getElementById('overview');
      if (defaultPanel) defaultPanel.classList.add('active');
      tabId = 'overview';
    }

    tabButtons.forEach(btn => {
      if (btn.dataset.tab === tabId) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    if (history.pushState) {
      history.pushState(null, null, '#' + tabId);
    } else {
      location.hash = '#' + tabId;
    }
  }

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      switchTab(btn.dataset.tab);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  });

  if (window.location.hash) {
    switchTab(window.location.hash);
  }

  window.addEventListener('hashchange', () => {
    switchTab(window.location.hash);
  });

  // --- 2. Copy Code to Clipboard ---
  const copyButtons = document.querySelectorAll('.btn-copy');
  copyButtons.forEach(btn => {
    btn.addEventListener('click', async () => {
      const container = btn.closest('.code-block');
      if (!container) return;
      const codeEl = container.querySelector('pre code, pre');
      if (!codeEl) return;

      const originalHtml = btn.innerHTML;
      try {
        await navigator.clipboard.writeText(codeEl.innerText.trim());
        btn.innerHTML = '<span>✓ Скопировано!</span>';
        btn.style.color = '#34d399';
        setTimeout(() => {
          btn.innerHTML = originalHtml;
          btn.style.color = '';
        }, 2000);
      } catch (err) {
        console.error('Clipboard copy failed:', err);
      }
    });
  });

  // --- 3. Interactive Screenshots Carousel ---
  const track = document.getElementById('carousel-track');
  const slides = document.querySelectorAll('.carousel-slide');
  const dotsContainer = document.getElementById('carousel-dots');
  const prevBtn = document.getElementById('carousel-prev');
  const nextBtn = document.getElementById('carousel-next');

  let currentIndex = 0;
  const totalSlides = slides.length;
  let autoPlayTimer = null;

  if (track && totalSlides > 0) {
    // Generate dots
    dotsContainer.innerHTML = '';
    for (let i = 0; i < totalSlides; i++) {
      const dot = document.createElement('button');
      dot.className = `carousel-dot ${i === 0 ? 'active' : ''}`;
      dot.setAttribute('aria-label', `Слайд ${i + 1}`);
      dot.addEventListener('click', () => goToSlide(i));
      dotsContainer.appendChild(dot);
    }
    const dots = dotsContainer.querySelectorAll('.carousel-dot');

    function updateCarousel() {
      track.style.transform = `translateX(-${currentIndex * 100}%)`;
      dots.forEach((dot, idx) => {
        dot.classList.toggle('active', idx === currentIndex);
      });
    }

    function goToSlide(index) {
      currentIndex = (index + totalSlides) % totalSlides;
      updateCarousel();
      resetAutoPlay();
    }

    function nextSlide() {
      goToSlide(currentIndex + 1);
    }

    function prevSlide() {
      goToSlide(currentIndex - 1);
    }

    if (prevBtn) prevBtn.addEventListener('click', prevSlide);
    if (nextBtn) nextBtn.addEventListener('click', nextSlide);

    // Keyboard support when viewport is focused / hovered
    const viewport = document.getElementById('carousel-viewport');
    if (viewport) {
      viewport.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowLeft') prevSlide();
        if (e.key === 'ArrowRight') nextSlide();
      });
    }

    // Auto Play every 5 seconds
    function startAutoPlay() {
      autoPlayTimer = setInterval(nextSlide, 5000);
    }

    function stopAutoPlay() {
      clearInterval(autoPlayTimer);
    }

    function resetAutoPlay() {
      stopAutoPlay();
      startAutoPlay();
    }

    const carouselWrap = document.querySelector('.carousel-wrap');
    if (carouselWrap) {
      carouselWrap.addEventListener('mouseenter', stopAutoPlay);
      carouselWrap.addEventListener('mouseleave', startAutoPlay);
    }

    startAutoPlay();

    // Touch swipe support for mobile
    let touchStartX = 0;
    let touchEndX = 0;

    track.addEventListener('touchstart', (e) => {
      touchStartX = e.changedTouches[0].screenX;
    }, { passive: true });

    track.addEventListener('touchend', (e) => {
      touchEndX = e.changedTouches[0].screenX;
      handleSwipe();
    }, { passive: true });

    function handleSwipe() {
      const diff = touchEndX - touchStartX;
      if (Math.abs(diff) > 40) {
        if (diff < 0) nextSlide();
        else prevSlide();
      }
    }
  }

  // --- 4. Lightbox Modal for Screenshots ---
  const modal = document.getElementById('lightbox-modal');
  const modalImg = document.getElementById('lightbox-img');
  const modalClose = document.getElementById('lightbox-close');

  if (modal && modalImg) {
    document.querySelectorAll('.carousel-slide').forEach(slide => {
      slide.addEventListener('click', (e) => {
        // Prevent lightbox if clicked on arrows
        const img = slide.querySelector('img');
        if (img) {
          modalImg.src = img.src;
          modalImg.alt = img.alt || 'Скриншот';
          modal.classList.add('active');
        }
      });
    });

    function closeModal() {
      modal.classList.remove('active');
    }

    if (modalClose) {
      modalClose.addEventListener('click', closeModal);
    }

    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeModal();
      }
    });

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modal.classList.contains('active')) {
        closeModal();
      }
    });
  }

  // --- 5. OS Detection for Highlight ---
  const userAgent = window.navigator.userAgent.toLowerCase();
  const winCard = document.getElementById('card-windows');
  const linuxCard = document.getElementById('card-linux');

  if (userAgent.includes('linux') && linuxCard && winCard) {
    linuxCard.classList.add('highlight');
    winCard.classList.remove('highlight');
  } else if (winCard) {
    winCard.classList.add('highlight');
  }

  // --- 6. Dynamic GitHub Release Parser ---
  async function fetchLatestRelease() {
    try {
      const res = await fetch('https://api.github.com/repos/MjKey/DonatonTimer/releases/latest');
      if (!res.ok) return;
      const data = await res.json();
      const version = (data.tag_name || '').replace(/^v/, '');
      if (!version) return;

      // Update version texts
      document.querySelectorAll('.brand-badge, .version-text').forEach(el => {
        el.textContent = 'v' + version;
      });
      const heroPill = document.querySelector('.hero-pill-text');
      if (heroPill) {
        heroPill.textContent = `DonatonTimer v${version} — Свежий релиз`;
      }

      // Map assets by filename patterns
      if (Array.isArray(data.assets)) {
        data.assets.forEach(asset => {
          const name = asset.name.toLowerCase();
          const url = asset.browser_download_url;

          // Windows Setup
          if (name.endsWith('setup.exe') || (name.endsWith('.exe') && !name.includes('portable'))) {
            const btn = document.getElementById('dl-win-setup');
            if (btn) btn.href = url;
          }
          // Windows Portable
          else if (name.endsWith('.zip') && name.includes('portable')) {
            const btn = document.getElementById('dl-win-portable');
            if (btn) btn.href = url;
          }
          // Linux x86_64 AppImage
          else if (name.endsWith('.appimage') && (name.includes('x86_64') || name.includes('x64'))) {
            const btn = document.getElementById('dl-linux-appimage');
            if (btn) btn.href = url;
          }
          // Linux ARM64 AppImage
          else if (name.endsWith('.appimage') && (name.includes('arm64') || name.includes('aarch64'))) {
            const btn = document.getElementById('dl-linux-arm64');
            if (btn) btn.href = url;
          }
          // Linux DEB (amd64)
          else if (name.endsWith('.deb') && (name.includes('amd64') || name.includes('x64'))) {
            const btn = document.getElementById('dl-linux-deb');
            if (btn) btn.href = url;
          }
          // Linux RPM (x86_64)
          else if (name.endsWith('.rpm') && (name.includes('x86_64') || name.includes('amd64'))) {
            const btn = document.getElementById('dl-linux-rpm');
            if (btn) btn.href = url;
          }
          // Linux tar.gz (x86_64)
          else if (name.endsWith('.tar.gz') && (name.includes('x86_64') || name.includes('x64'))) {
            const btn = document.getElementById('dl-linux-targz');
            if (btn) btn.href = url;
          }
        });
      }
    } catch (err) {
      console.warn('Could not fetch latest release info, using default links:', err);
    }
  }

  fetchLatestRelease();
});
