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
default_height=30000
browser.driver.set_window_size(default_width,default_height)
dimensions=browser.driver.get_window_size()
print("Browser resolution set: %sx%s" % (dimensions['width'], dimensions['height']))
fxheadless_data_dir = os.path.realpath(sys.argv[2])
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

expandComments=False
expandPosts=False
takeScreenshots=False

previous_comments_xpath=".//span[contains(text(), 'previous comments')]"
fname=sys.argv[3]
print("Loading URLs from " + fname)
with open(fname) as f:
  url_counter=0
  for url in f:
    url_counter+=1
    browser.driver.set_window_size(default_width,default_height)
    url = url.strip()
    page={"url": url, "exceptions": {"expando": []}, "screenshot_paths": []}
    print("[%s] Visiting URL: %s" % (url_counter, url))
    browser.visit(url)
    page["title"]=browser.find_by_css('html head title').first.html
    print('Title: %s' % page["title"])
    if page["title"] == "Google+":
      print("ERROR: Likely hit the 'no longer available' wall")
      if browser.is_element_present_by_css('div.wTeX3'):
        message=browser.find_by_css('div.wTeX3').first.text
        print(message)
        if message.startswith('Google+ is no longer available '):
          url+="?hl=en"
          print("Trying again with different locale: %s" % url)
          browser.visit(url)
          page["title"]=browser.find_by_css('html head title').first.html
          print('Title: %s' % page["title"])
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
      print('Error %s: %s' % (page["status_code"], page["error"]))
    
    browser.driver.set_window_size(default_width,default_height)
    if expandComments:
      if browser.is_element_present_by_xpath(previous_comments_xpath, 1):
        expand_links=browser.find_by_xpath(previous_comments_xpath)
        counter=0
        for link in expand_links:
          if counter > 3:
            break
          try:
            link.click()
          except Exception as x:
            print("Exception while expanding object", str(link), str(x))
            page["exceptions"]["expando"].append(str(x))
          print("clicked read more", link['class'])
          counter+=1
      else:
        page["exceptions"]["expando"].append("Could not find element to expand comments")
        print(page["exceptions"]["expando"][-1])
    if expandPosts:
      if browser.is_element_present_by_css('span[jsname=xuZcmb],span[jsname=KFvZSd]', 1):
        read_more_links=browser.find_by_css('span[jsname=xuZcmb],span[jsname=KFvZSd]')
        counter=0
        for link in read_more_links:
          if counter > 5:
            break
          try:
            link.click()
          except Exception as x:
            print("Exception while expanding object", str(link), str(x))
            page["exceptions"]["expando"].append(str(x))
          print("clicked read more", link['class'])
          counter+=1
      time.sleep(2)
    try:
      paths=["div.Q1Rnie", "div.m2bmxb", "div[role=main]", "body", "html"]
      current_path=paths.pop(0)
      while (browser.is_element_not_present_by_css(current_path, 0) and len(paths) > 0):
        current_path=paths.pop(0)
        
      total_height=browser.driver.execute_script('return document.querySelector("%s").offsetHeight + 300' % current_path)
      browser.driver.set_window_size(default_width,total_height)
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
    if takeScreenshots:
      try:
        paths=["div.Q1Rnie", "div.m2bmxb", "div[role=main]", "body", "html"]
        current_path=paths.pop(0)
        while (browser.is_element_not_present_by_css(current_path, 0) and len(paths) > 0):
          current_path=paths.pop(0)
          
        total_height=browser.driver.execute_script('return document.querySelector("%s").offsetHeight' % current_path)
        total_height+=800
        browser.driver.set_window_size(default_width,total_height)
        dimensions=browser.driver.get_window_size()
        print("Browser resolution set to %sx%s" % (dimensions['width'], dimensions['height']))
      except Exception as x:
        print("Changing resolution failed: %s" % str(x))
      browser.execute_script("window.scrollTo(0, 0);")
      screenshots_dir = os.path.join(saved_pages_dir, subdir, 'screenshots')
      if not os.path.isdir(screenshots_dir):
        os.makedirs(screenshots_dir)
      counter=0
      remainder_height=total_height
      try:
        scroll_y=0
        while remainder_height > 0:
          height=remainder_height
          if height > default_height:
            height=default_height
          browser.driver.set_window_size(dimensions['width'], height)
          print("Scrolling to %s" % scroll_y)
          browser.execute_script("window.scrollTo(0, %s);" % scroll_y)
          print("Resized browser to %sx%s" % (dimensions['width'], height))
          screenshot_filepath = os.path.join(screenshots_dir, '%s-%s-%sx%s' % (filename, counter, dimensions['width'], height))
          print("Trying to save screenshot to: '%s.png'" % screenshot_filepath)
          screenshot_filepath=browser.screenshot(name=screenshot_filepath, suffix='.png')
          page["screenshot_paths"].append(screenshot_filepath)
          print("Saved screenshot to: " + screenshot_filepath)
          counter+=1
          offset=300
          remainder_height-=height
          remainder_height+=offset
          scroll_y+=(height - offset)
          if remainder_height == offset:
            break

      except Exception as x:
        print("Exception while trying to save screenshot: ")
        print(dir(x))
        page["exceptions"]["taking_screenshot"] = str(dir(x))

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
    # time.sleep(0.5)
    print("\n")

