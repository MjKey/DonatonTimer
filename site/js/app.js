document.addEventListener('DOMContentLoaded', () => {
  // --- 1. Tab Navigation (#hash support) ---
  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanels = document.querySelectorAll('.tab-panel');

  function switchTab(tabId) {
    if (!tabId) tabId = 'overview';
    // Clean hash if provided with #
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
      // Fallback to overview
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

    // Update URL hash without jumping
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

  // Handle direct link with hash
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

  // --- 3. Lightbox Modal for Screenshots ---
  const modal = document.getElementById('lightbox-modal');
  const modalImg = document.getElementById('lightbox-img');
  const modalClose = document.getElementById('lightbox-close');

  if (modal && modalImg) {
    document.querySelectorAll('.gallery-card').forEach(card => {
      card.addEventListener('click', () => {
        const img = card.querySelector('img');
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

  // --- 4. OS Detection for Friendly Highlight ---
  const userAgent = window.navigator.userAgent.toLowerCase();
  const winCard = document.getElementById('card-windows');
  const linuxCard = document.getElementById('card-linux');

  if (userAgent.includes('linux') && linuxCard && winCard) {
    linuxCard.classList.add('highlight');
    winCard.classList.remove('highlight');
  } else if (winCard) {
    winCard.classList.add('highlight');
  }
});
