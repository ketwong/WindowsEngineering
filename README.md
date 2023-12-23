# WindowsEngineering

## Clone-HyperVM.ps1
**Example usage**
```
PS C:\users\suket\Desktop> .\Clone-HyperVM.ps1 -MasterVmName "dev-master" -NewVmName "groceries_io"
2023-12-23 02:07:10 : Starting Clone-HyperVM script.
2023-12-23 02:14:14 : Exported VM 'dev-master' to 'C:\temp\dev-master'.
2023-12-23 02:19:36 : Imported VM from 'C:\temp\dev-master\Virtual Machines\AB6FED31-E3AA-41F4-9C43-C122DE5EF34D.vmcx'.
2023-12-23 02:19:36 : Renamed VM to 'groceries_io'.
2023-12-23 02:19:36 : Cleaned up temporary files in 'C:\temp\dev-master'.
2023-12-23 02:19:36 : Script completed in 746.3540701 seconds.
PS C:\users\suket\Desktop>
```
