
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
###########################################################################

In the file encrypt-vm.ps1 :

I used default VMware policy for encryption called VM Encryption Policy if you are using your own policy you need to change it in the line 103

$EncryptionPolicy = Get-SpbmStoragePolicy -name "POLICY_NAME_HERE_or_DEFAULT_ONE" 

In line 111 and 122 you need to provide your KMS Cluster ID

Get-VM $v | Enable-VMEncryption -policy $EncryptionPolicy -KMSClusterId "KMS_ID"

