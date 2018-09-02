using System;
using System.Linq;
using System.Net;
using System.Security.Cryptography.X509Certificates;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;

namespace HBD.ServiceFabric.Listeners
{
    public static class KestrelListenerExtentions
    {
        public static X509Certificate2 GetCertificateFromStore(string thumbprint, StoreName fromStore = StoreName.My)
        {
            if (thumbprint == null) throw new ArgumentNullException(nameof(thumbprint));

            var tt = Regex.Replace(thumbprint.ToUpper(), "[^A-F0-9]", ""); //Keep only hex digits

            //Load Certificate from Store by Thumbprint
            using (var store = new X509Store(fromStore, StoreLocation.LocalMachine))
            {
                store.Open(OpenFlags.ReadOnly);

                var cert = store
                    .Certificates
                    .OfType<X509Certificate2>()
                    .FirstOrDefault(x => x.Thumbprint != null && x.Thumbprint.Equals(tt, StringComparison.OrdinalIgnoreCase));

                store.Close();
                return cert;
            }
        }

        private static X509Certificate2 TryGetCertificateFromStore(string thumbprint)
            => GetCertificateFromStore(thumbprint)
                ?? GetCertificateFromStore(thumbprint, StoreName.TrustedPublisher)
                ?? GetCertificateFromStore(thumbprint, StoreName.TrustedPeople)
                ?? GetCertificateFromStore(thumbprint, StoreName.Root)
                ?? GetCertificateFromStore(thumbprint, StoreName.CertificateAuthority);

        public static IWebHostBuilder UseKestrelHttps(this IWebHostBuilder hostBuilder, int port, Func<X509Certificate2> certFactory)
        {
            if (certFactory == null)
                throw new ArgumentNullException(nameof(certFactory));

            if (port <= 0)
                throw new ArgumentOutOfRangeException(nameof(port));

            return hostBuilder.UseKestrel(op => op.Listen(IPAddress.IPv6Any, port,
                listenConfig =>
                {
                    var cert = certFactory.Invoke();
                    if (cert == null)
                        throw new ArgumentNullException(nameof(certFactory));
                    listenConfig.UseHttps(cert);
                }));
        }

        public static IWebHostBuilder UseKestrelHttps(this IWebHostBuilder hostBuilder, int port, string certificatePath, string password)
            => hostBuilder.UseKestrelHttps(port, () => new X509Certificate2(certificatePath, password));

        public static IWebHostBuilder UseKestrelHttps(this IWebHostBuilder hostBuilder, int port, X509Certificate2 certificate)
           => hostBuilder.UseKestrelHttps(port, () => certificate);

        /// <summary>
        /// Setup https for Kestrel. The certificate will try to find from Persional,TrustedPublisher,TrustedPeople,Root and CertificateAuthority by Thumbprint.
        /// </summary>
        /// <param name="hostBuilder"></param>
        /// <param name="port">the port of https</param>
        /// <param name="thumbprint">certificate thumbprint</param>
        /// <exception cref="ArgumentNullException">if certificate is not found</exception>
        /// <returns></returns>
        public static IWebHostBuilder UseKestrelHttps(this IWebHostBuilder hostBuilder, int port, string thumbprint)
            => hostBuilder.UseKestrelHttps(port, () => TryGetCertificateFromStore(thumbprint));
    }
}
