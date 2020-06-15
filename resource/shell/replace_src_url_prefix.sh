
# 替换博客文章中的图片前缀为国内域名地址
find . -name "*.md" -type f | xargs sed -i '' 's/https:\/\/raw.githubusercontent.com\/imekaku\/MyPicture\/master\/github-blog-pic/http:\/\/cdn.mycdnsite.com\/blog-src/g'

# 替换博客thinking中的图片前缀为国内域名地址
find . -name "*.md" -type f | xargs sed -i '' 's/https:\/\/raw.githubusercontent.com\/imekaku\/MyPicture\/master\/github-thinking-pic/http:\/\/cdn.mycdnsite.com\/blog-src/g'