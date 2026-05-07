require "fileinto";

if header :matches "X-Spam-Status" "Yes*" {
	fileinto "Junk";
}
