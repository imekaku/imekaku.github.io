
# 替换博客文章中的图片前缀为国内域名地址
find . -name "*.md" -type f | xargs sed -i '' 's/https:\/\/raw.githubusercontent.com\/imekaku\/MyPicture\/master\/github-blog-pic/http:\/\/blogcdn.qihope.com\/github-blog-pic/g'

# 替换博客thinking中的图片前缀为国内域名地址
find . -name "*.md" -type f | xargs sed -i '' 's/https:\/\/raw.githubusercontent.com\/imekaku\/MyPicture\/master\/github-thinking-pic/http:\/\/blogcdn.qihope.com\/github-thinking-pic/g'

# 替换博客reading中的图片前缀为国内域名地址
find . -name "*.md" -type f | xargs sed -i '' 's/https:\/\/raw.githubusercontent.com\/imekaku\/MyPicture\/master\/github-reading-pic/https:\/\/blogcdn.qihope.com\/github-reading-pic/g'

# 替换http为https
find . -name "*.md" -type f | xargs sed -i '' 's/http:\/\/blogcdn.qihope.com\/github-thinking-pic/https:\/\/blogcdn.qihope.com\/github-thinking-pic/g'
find . -name "*.md" -type f | xargs sed -i '' 's/http:\/\/blogcdn.qihope.com\/github-blog-pic/https:\/\/blogcdn.qihope.com\/github-blog-pic/g'