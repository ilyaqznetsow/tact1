import type { Config } from 'jest';

const config: Config = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    testPathIgnorePatterns: ['/node_modules/', '/dist/', 'Task2', 'Task3', 'Task4', 'Task5'],
    workerThreads: true,   
};

export default config;
