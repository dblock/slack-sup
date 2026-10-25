require 'spec_helper'

describe 'Versioned website assets', :js, type: :feature do
  it 'loads local images with their dimensions after a browser reload' do
    visit '/?version=1'
    page.driver.browser.navigate.refresh
    expect(page).to have_css('img[src^="/img/"]', minimum: 1)
    images = page.evaluate_async_script(<<~JS)
      var done = arguments[arguments.length - 1];
      var images = Array.from(document.querySelectorAll('img[src^="/img/"]'));
      Promise.all(images.map(function(image) {
        return image.decode().then(function() {
          return /\\?v=[a-f0-9]{64}$/.test(image.src) && image.naturalWidth > 0 && image.naturalHeight > 0;
        }, function() { return false; });
      })).then(done);
    JS
    expect(images).not_to be_empty
    expect(images).to all(be true)

    loaded = page.evaluate_async_script(<<~JS)
      var done = arguments[arguments.length - 1];
      var url = getComputedStyle(document.querySelector('header')).backgroundImage;
      var image = new Image();
      image.onload = function() { done(image.naturalWidth > 0 && image.naturalHeight > 0 && /\\?v=[a-f0-9]{64}$/.test(image.src)); };
      image.onerror = function() { done(false); };
      image.src = url.slice(4, -1).replace(/^["']|["']$/g, '');
    JS
    expect(loaded).to be true
  end
end
