
# Use the following commands to test the health of the Domain Controllers and
# their replication.

# Test the Domain Controller health with dcdiag
Test-ADDomainControllerDiagnostic -ComputerName 'LON-DC1.contoso.com', 'LON-DC2.contoso.com'

# Test the Partition Replication health with repadmin
Test-ADDomainControllerReplication -ComputerName 'LON-DC1.contoso.com', 'LON-DC2.contoso.com'
