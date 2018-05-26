using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Ex1
{
    class Program
    {
        // main will be executed as the entrypoint of this console application
        static void Main(string[] args)
        {
            int result = Add2(2, 4);
            ShowResult(result);
            Console.ReadKey(true);
        }

        private static int Add2(int n1, int n2)
        {
            return n1 + n2;
        }

        private static void ShowResult(int result)
        {
            Console.WriteLine(result);
        }
    }
}
