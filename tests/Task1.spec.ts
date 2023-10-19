import { Blockchain, SandboxContract } from '@ton-community/sandbox';
import '@ton-community/test-utils';
import { toNano } from 'ton-core';
import { Task1, Add } from '../wrappers/Task1';


describe('Task1', () => {
    let blockchain: Blockchain;
    let task1: SandboxContract<Task1>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        task1 = blockchain.openContract(await Task1.fromInit());
        const deployer = await blockchain.treasury('deployer');
        const deployResult = await task1.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: task1.address,
            deploy: true,
            success: true,
        });
    });

    it('test', async () => {
        console.log( await task1.getCounter());
        let owner = await blockchain.treasury('owner');
        await task1.send(owner.getSender(), {value: toNano('0.05')}, {$$type: 'Add', queryId:0n, number: 1n} );
        console.log(await task1.getCounter());
        // console.log(await task1.getSlicer());
    });
});
