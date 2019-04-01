import os
import sys
import urllib.parse
import time
import datetime
import json
from splinter import Browser
# argv[1] #=> Browser profile
# argv[2] #=> output parent directory
# argv[3] #=> input urls list
browser = Browser('firefox', headless=True, profile=sys.argv[1])
print("Browser started")
default_width=1920
default_height=60000
browser.driver.set_window_size(default_width,default_height)
print("Browser resolution set")
fxheadless_data_dir = sys.argv[2]
try:
  if not os.path.isdir(fxheadless_data_dir):
    os.makedirs(fxheadless_data_dir)
except Exception as x:
  print(x)
saved_pages_dir = os.path.join(fxheadless_data_dir, 'saved_pages')
try:
  if not os.path.isdir(saved_pages_dir):
    os.makedirs(saved_pages_dir)
except Exception as x:
  print(x)
saved_pages_json_path = os.path.join(fxheadless_data_dir, 'saved_pages-%s.json' % '{0:%Y-%m-%d-%H-%M}'.format(datetime.datetime.now()))
pages = []

previous_comments_xpath=".//span[contains(text(), 'previous comments')]"

fname=sys.argv[3]
print("Loading URLs from " + fname)
with open(fname) as f:
  for url in f:
    url = url.strip()
    page={"url": url, "exceptions": {}}
    print("Visiting URL: " + url)
    browser.visit(url)
    page["title"]=browser.find_by_css('html head title').first.html
    if page["title"] == "302 Moved":
      page["status_code"]="302"
      page["error"]=browser.find_by_css('html body').first.text
      print(browser.html, "302 Moved detected!")
      if browser.is_element_present_by_css('html body a'):
        if browser.find_by_css('html head title').first.href.startswith("https://www.google.com/sorry"):
          print("Looks like we hit a CAPTCHA")
      input("Looks like this page has moved, possibly due to a Captcha request? Press Enter to continue...")
    if browser.is_element_present_by_id('af-error-container'):
      browser.driver.set_window_size(1920,1080)
      page["status_code"]=browser.find_by_css('#af-error-container > p > b').first.html.strip('.')
      page["error"]=browser.find_by_css('#af-error-container > p + p').first.text
    
    browser.driver.set_window_size(default_width,default_height)
    try:
      if browser.is_element_present_by_xpath(previous_comments_xpath, 1):
        browser.find_by_xpath(previous_comments_xpath).first.click()
        print("Clicked to expand comments. Sleeping for a second.")
        time.sleep(1)
      else:
        page["exceptions"]["expanding_comments"] = "Could not find element to expand comments"
        print(page["exceptions"]["expanding_comments"])
    except Exception as x:
      print("Exception while expanding comments", x)
      page["exceptions"]["expanding_comments"] = str(x)
    try:
      paths=["div.Q1Rnie", "div.m2bmxb", "div[role=main]", "body", "html"]
      current_path=paths.pop(0)
      while (browser.is_element_not_present_by_css(current_path, 0) and len(paths) > 0):
        current_path=paths.pop(0)
        
      height=browser.driver.execute_script('return document.querySelector("%s").offsetHeight + 300' % current_path)
      browser.driver.set_window_size(default_width,height)
      dimensions=browser.driver.get_window_size()
      print("Browser resolution set to %sx%s" % (dimensions['width'], dimensions['height']))
    except Exception as x:
      print("Changing resolution failed: %s" % str(x))
    try:
      plus_url_prefix='https://plus.google.com/'
      subdir = ''
      if url.startswith(plus_url_prefix):
        subdir = 'plus.google.com'
        filename = urllib.parse.quote(url[len(plus_url_prefix):], '')
        if filename.startswith(urllib.parse.quote('+')):
          filename = filename[len(urllib.parse.quote('+')):]
        try:
          saved_pages_subdir=os.path.join(saved_pages_dir, subdir)
          if not os.path.isdir(saved_pages_subdir):
            os.makedirs(saved_pages_subdir)
        except Exception as x:
          print(x)
      else:
        filename = urllib.parse.quote(url, '')
      page["base_filename"] = filename
      output_filepath = os.path.join(saved_pages_dir, subdir, filename)
      page["base_filepath"] = output_filepath
    except Exception as x:
      print("Exception while joining base file paths: ", x)
      page["exceptions"]["joining_filepath"] = str(x)
    try:
      page["html_output_filepath"] = output_filepath + '.html'
      with open(page["html_output_filepath"], "w") as of:
        of.write(browser.html)
      print("Saved HTML to: " + page["html_output_filepath"])
    except Exception as x:
      print("Exception while saving HTML: ", x)
      page["exceptions"]["saving_html"] = str(x)
    try:
      screenshots_dir = os.path.join(saved_pages_dir, subdir, 'screenshots')
      try:
        if not os.path.isdir(screenshots_dir):
          os.makedirs(screenshots_dir)
      except Exception as x:
        print(x)
      dimensions=browser.driver.get_window_size()
      screenshot_filepath = os.path.join(screenshots_dir, '%s-%sx%s' % (filename, dimensions['width'], dimensions['height']))
      print("Trying to save screenshot to: '%s.png'" % screenshot_filepath)
      page["screenshot_path"] = browser.screenshot(name=screenshot_filepath, suffix='.png', full=True)
      print("Saved screenshot to: " + page["screenshot_path"])
    except Exception as x:
      print("Exception while trying to save screenshot: ", x)
      page["exceptions"]["taking_screenshot"] = str(x)
    metadata_filepath = output_filepath + '.metadata.json'
    try:
      with open(metadata_filepath, "w") as of:
        of.write(json.dumps(page))
      print("Dumped page JSON to: " + metadata_filepath)
    except Exception as x:
      print("Exception while dumping page JSON: ", x)
      page["exceptions"]["saving_metadata"] = str(x)
    try:
      with open(saved_pages_json_path, "w") as of:
        of.write(json.dumps(pages))
    except Exception as x:
      print("Exception while dumping pages JSON: ", x)
    print("Dumped pages JSON to: " + saved_pages_json_path)
    pages.append(page)
    time.sleep(0.5)
    print("\n")

